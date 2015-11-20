class Feed < ActiveRecord::Base
	include PgSearch

  	pg_search_scope :search,
  		:using => {
    		:tsearch => {
    			:any_word => true, 
    			:ignoring => :accents,
    			:prefix => true
    		}
    	}, 
  		:against => {
    		:name => 'A',
    		:description => 'B'
    	}

	acts_as_mappable :default_units => :kms,
	                 :default_formula => :sphere,
	                 :distance_field_name => :distance,
	                 :lat_column_name => :central_mass_latitude,
	                 :lng_column_name => :central_mass_longitude    	    	
    	
	has_many :feed_venues, :dependent => :destroy
	has_many :venues, through: :feed_venues
	has_many :venue_comments, through: :venues
	has_many :feed_users, :dependent => :destroy
	has_many :users, through: :feed_users
	has_many :feed_recommendations, :dependent => :destroy
	has_many :feed_invitations, :dependent => :destroy
	has_many :activity_feeds, :dependent => :destroy

	has_many :activities

	belongs_to :user

	def is_private?
		self.code != nil
	end

	def Feed.calibrate_feed_venue_activity
		feeds = Feed.all
		for feed in feeds
			for feed_venue in feed.feed_venues
				if Activity.where("feed_venue_id = ?", feed_venue.id).first.nil? == true	
					Activity.create!(:feed_id => feed_venue.feed.id, :activity_type => "added venue", :feed_venue_id => feed_venue.id, :venue_id => feed_venue.venue_id, :user_id => feed_venue.user_id, :adjusted_sort_position => (feed_venue.created_at).to_i)
				end
			end
			feed.update_columns(num_venues: feed.feed_venues.count)
		end
	end

	def comments
		venue_ids = "SELECT venue_id FROM feed_venues WHERE feed_id = #{self.id}"
		comments = VenueComment.where("venue_id IN (#{venue_ids})").includes(:venue).order("time_wrapper DESC")
	end

	def activity_of_the_day
		activity_ids = "SELECT activity_id FROM activity_feeds WHERE feed_id = #{self.id} AND adjusted_sort_position IS NOT NULL"
		Activity.where("id IN(#{activity_ids}) AND created_at >= ?", Time.now-1.day).includes(:feed, :user, :venue, :venue_comment).order("adjusted_sort_position DESC")
	end

	def latest_image_thumbnail_url
		venue_ids = "SELECT venue_id FROM feed_venues WHERE feed_id = #{self.id}"
		url = VenueComment.where("venue_id IN (#{venue_ids}) AND (NOW() - created_at) <= INTERVAL '1 DAY'").order("id DESC").first.try(:lowest_resolution_image_avaliable)
	end

	def is_venue_present?(v_id)
		FeedVenue.where("feed_id = ? AND venue_id = ?", self.id, v_id).any?
	end

	def new_content_present?
		latest_viewed_time_wrapper = latest_viewed_time || (Time.now + 1.minute)
		self.venue_comments.where("venue_comments.created_at > ?", latest_viewed_time_wrapper).count
	end

	def self.feeds_in_venue(venue_id)
		feed_ids = "SELECT feed_id FROM feed_venues WHERE venue_id = (#{venue_id})"
		Feed.where("id IN (#{feed_ids})").order("name ASC")
	end

	def self.feeds_in_cluster(cluster_venue_ids)
		feed_ids = "SELECT feed_id FROM feed_venues WHERE venue_id IN (#{cluster_venue_ids})"
		Feed.where("id IN (#{feed_ids})").includes(:user, :feed_users).order("name ASC")		
	end

	def update_media
		self.venues.each do |v|
			v.instagram_pull_check
		end
	end

	def has_added?(new_user)
		self.feed_users.where("user_id = ? AND feed_id = ?", new_user.id, id).any?
	end

	def is_subscribed?(target_user)
		fu = FeedUser.where("user_id = ? AND feed_id = ?", target_user.id, id).first
		if fu != nil
			fu.is_subscribed
		else
			false
		end
	end

	def calibrate_num_members
		self.update_columns(num_users: self.feed_users.count)
	end

	def relevance_to_user_score(user_lat, user_long)
		#calculate a feed's relevance to user based on the proximity of its central mass point, and popularity (as determined by number of members and underlying venues)
		#Formula: (v_weight*num_venues)+(m_weight*num_members)+(proximity_score)

		#if List center is (0 kms, 10 kms] to user proximity score is 10 , (10 kms, 100 kms] => 5, (100 kms, 1000 kms] => 2, >10000 km => 1
		city_bound = 20
		state_bound = 100
		country_bound = 1000
		continent_bound =  10000
		
		v_weight = 1
		m_weight = 0.3

		proximity = Geocoder::Calculations.distance_between([central_mass_latitude, central_mass_longitude], [user_lat, user_long], :units => :km)
		if proximity <= city_bound
			proximity_score = 10
		elsif proximity <= state_bound
			proximity_score = 5
		elsif proximity <= country_bound
			proximity_score = 2
		elsif proximity > country_bound
			proximity_score = 1
		end
		
		relevance_score = (v_weight * num_venues) + (m_weight * num_users) + proximity_score
	end

	def new_content_for_user?(target_user)
		feeduser = FeedUser.where("user_id = ? AND feed_id = ?", target_user.id, self.id).first
		if self.latest_content_time == nil
			false
		elsif feeduser.last_visit == nil
			true
		else
			if self.latest_content_time > feeduser.last_visit
				true
			else
				false
			end
		end
	end

	def self.meta_search(query)
		direct_results = Feed.where("name LIKE (?) OR description LIKE (?)", "%"+query+"%", "%"+query+"%").to_a
		meta_results = Feed.joins(:feed_venues).joins(:venues => :meta_datas).where("meta LIKE (?)", query+"%").where("feeds.id NOT IN (?)", direct_results.map(&:id)).to_a.uniq{|x| x.id}.count
		merge = direct_results << meta_results
		results = merge.flatten.sort_by{|x| x.name}
	end

	def self.categories
		default_categories = ["parks", "bars", "coffee", "dog", "cat", "mouse", "house", "literature", "sports", "france", "germany", "netherlands", "russia", "travel", "cracerjacks", "watermellons"]
		used_categories = FeedRecommendation.uniq.pluck(:category)
		if used_categories.count == 0
			return default_categories
		else
			return used_categories
		end
	end

	def update_geo_mass_center
		#Calculation for the geographic midpoint of a List based on locations of underlying Venues
		underlying_venues = self.venues
		if underlying_venues.count > 0
			total_weight = 0
			sum_x = 0
			sum_y = 0
			sum_z = 0
			for venue in underlying_venues
				#conversion to cartesian coordinates
				lat_radians = venue.latitude * Math::PI/180
				long_radians = venue.longitude * Math::PI/180
				
				x = Math.cos(lat_radians) * Math.cos(long_radians)
				y = Math.cos(lat_radians) * Math.sin(long_radians)
				z = Math.sin(lat_radians)

				#set weight if neccessary
				venue_weight = 1
				total_weight += venue_weight

				sum_x += x * venue_weight 
				sum_y += y * venue_weight
				sum_z += z * venue_weight
			end

			weighted_x = sum_x / total_weight
			weighted_y = sum_y / total_weight
			weighted_z = sum_z / total_weight

			central_long_radians = Math.atan2(weighted_y, weighted_x)
			hyp = Math.sqrt(weighted_x ** 2 + weighted_y ** 2)
			central_lat_radians = Math.atan2(weighted_z, hyp) 

			geo_mass_lat = central_lat_radians * 180/Math::PI
			geo_mass_long = central_long_radians * 180/Math::PI

			self.update_columns(central_mass_latitude: geo_mass_lat)
			self.update_columns(central_mass_longitude: geo_mass_long)
			return [geo_mass_lat, geo_mass_long]
		else
			nil
		end
	end

	def self.initial_recommendations(selected_categories)
		if selected_categories != nil
			FeedRecommendation.where("category IN (?) AND active IS TRUE", selected_categories)
		end
	end

	def venue_tweets
		venue_ids = "SELECT venue_id FROM feed_venues WHERE feed_id = #{self.id}"
		Tweet.where("venue_id IN (#{venue_ids})").order("timestamp DESC")
	end


end