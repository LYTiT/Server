class Feed < ActiveRecord::Base
	include PgSearch

	pg_search_scope :basic_search, #name and/or associated meta data
	against: :search_vector,
	using: {
	  tsearch: {
	    dictionary: 'english',
	    any_word: true,
	    prefix: true,
	    tsvector_column: 'search_vector'
	  }
	}  


	pg_search_scope :robust_search, lambda{|query, latitude, longitude|{
			:against => {
				:ts_name_vector => 'A', 
				:ts_description_vector => 'C',
				:ts_categories_vector => 'C',
				:ts_venue_descriptives_vector => 'D'	              	
			},
			:using => {
				:tsearch => { 
					dictionary: 'english',
					any_word: true,
					prefix: true
				}
			},
			:query => query,
			:ranked_by => "CASE (:tsearch > 0.1 AND :tsearch < 0.5 AND num_venues > 0) WHEN TRUE THEN round(cast(:tsearch/(ST_Distance(central_mass_lonlat_geography, ST_GeographyFromText('SRID=4326;POINT(#{longitude} #{latitude})'))/1000) AS NUMERIC), 1) ELSE (CASE :tsearch > 0.5 WHEN TRUE THEN round(cast(:tsearch AS NUMERIC), 1) ELSE -1.0 END) END",
			#"(:tsearch * ((floor(0.5-:tsearch)+1) + (floor(0.5-:tsearch)+1) * 1/(ST_Distance(central_mass_lonlat_geography, ST_GeographyFromText('SRID=4326;POINT(#{latitude} #{longitude})'))/1000.0)))",
			:order_within_rank => "(num_venues * 5.0) + (num_users * 1.0)"
		}
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

	has_many :activities, :dependent => :destroy
	has_many :reported_objects, :dependent => :destroy

	has_many :feed_join_requests, :dependent => :destroy

	has_many :list_category_entries, :dependent => :destroy
	has_many :list_categories, through: :list_category_entries

	belongs_to :user

	def partial 
		{:name => self.name, :id => self.id, :color => self.feed_color, :preview_image_url => self.preview_image_url, :cover_image_url => self.cover_image_url, :creator_id => self.user_id}
	end

	def activity_feed
		self.activities.where("adjusted_sort_position > ?", (Time.now-1.day).to_i).order("adjusted_sort_position DESC")
	end

	def Feed.search(query, user_lat=40.741140 , user_long=-73.981917)
		#like_query = query.downcase+'%'
		#direct_match_ids = "SELECT id FROM feeds WHERE LOWER(name) LIKE ('#{like_query}')"
		query.gsub!(/\d\s?/, "")
		if query.last(2).count(query.last) > 1
			query = query.chomp(query.last)
		end
		v_weight = 0.5
		m_weight = 0.1    

		search_results = Feed.robust_search(query, user_lat, user_long).with_pg_search_rank.where("pg_search.rank >= 0.0").limit(10).order("pg_search_rank DESC")#.where("pg_search.rank > 0.1").limit(10).order("num_venues*#{v_weight}+num_users*#{m_weight}")
		#top_search_results = search_results.select { |venue| venue.pg_search_rank >= 0.2 }
		#Feed.where("id in (#{direct_match_ids})").limit(5)+
		search_results		
	end

	def put_in_spotlyt(set=true)
		self.update_columns(in_spotlyt: set)
	end

	def register_open(u_id)
		feed_user = self.feed_users.where("user_id = ?", u_id).first
		if feed_user != nil
			if self.user_id != nil and self.user_id == u_id
				value = 0.2
			else
				value = 0.1
			end
			feed_user.update_interest_score(value)
		end
		self.update_underlying_venues
	end

	def update_venue_attributes(added_venue)
		update_venue_categories(added_venue)
		#update_descriptives(added_venue)
	end

	def update_venue_categories(venue)
	  tracker_key = "underlying_venue_ids"
	  added_value = 5.0

	  venue_attributes_hash = self.venue_attributes
	  venue_categories_hash = self.venue_attributes["venue_categories"]
	  
	  venue.categories.each do |label, category|
	    category = category.downcase
	    if venue_categories_hash != nil and venue_categories_hash[category] != nil
	      underlying_source_ids = venue_categories_hash[category][tracker_key]
	      previous_score = venue_categories_hash[category]["weight"].to_f
	      if underlying_source_ids.include?(venue.id) == true
	        venue_categories_hash[category]["weight"] = previous_score + 0.01
	        venue_categories_hash[category]["latest_update_time"] = Time.now
	      else
	        updated_source_ids = underlying_source_ids << venue.id
	        venue_categories_hash[category]["weight"] = previous_score + added_value
	        venue_categories_hash[category][tracker_key] = updated_source_ids
	        venue_categories_hash[category]["latest_update_time"] = Time.now
	      end
	    else
	      venue_categories_hash[category] = {"weight" => 1.0, tracker_key => [venue.id], "latest_update_time" => Time.now}
	    end
	  end
	  venue_attributes_hash["venue_categories"] = venue_categories_hash
	  
	  self.update_columns(venue_attributes: venue_attributes_hash)
	end

	def update_descriptives(venue)
	  tracker_key = "searched_venue_ids"
	  added_value_multiplier = 1.2

	  venue_attributes_hash = self.venue_attributes
	  descriptives_hash = self.venue_attributes["descriptives"]

	  source_top_descriptives = Hash[venue.descriptives.to_a[0..4]]

	  source_top_descriptives.each do |descriptive, details|
	    descriptive = descriptive.downcase
	    if descriptives_hash != nil and descriptives_hash[descriptive] != nil
	      underlying_source_ids = descriptives_hash[descriptive][tracker_key]
	      previous_score = descriptives_hash[descriptive]["weight"].to_f
	      if underlying_source_ids.include?(venue.id) == true
	        descriptives_hash[descriptive]["weight"] = previous_score.to_f*1.05 #incrementing weight by 5%
	        descriptives_hash[descriptive]["latest_update_time"] = Time.now
	      else
	        update_source_ids = underlying_source_ids << venue.id
	        descriptives_hash[descriptive]["weight"] = (previous_score + details["weight"].to_f*added_value_multiplier)
	        descriptives_hash[descriptive][tracker_key] = update_source_ids
	        descriptives_hash[descriptive]["latest_update_time"] = Time.now
	      end
	    else
	      descriptives_hash[descriptive] = {"weight" => details["weight"].to_f, tracker_key => [venue.id], "latest_update_time" => Time.now}
	    end
	  end
	  venue_attributes_hash["descriptives"] = descriptives_hash
	  
	  self.update_columns(venue_attributes: venue_attributes_hash)
	end	

	def Feed.new_member_calibration(feed_id, user_id)
		user = User.find_by_id(user_id)
		feed = Feed.find_by_id(feed_id)
		if user != nil && feed != nil	
			feed.calibrate_num_members
			feed.increment!(:num_users, 1)
			user.increment!(:num_lists, 1)
			user.update_interests(feed, "joined_list")
		end
	end

	def Feed.lost_member_calibration(feed_id, user_id)
		feed = Feed.find_by_id(feed_id)
		user = User.find_by_id(user_id)

		if feed != nil
			feed.decrement!(:num_users, 1)
		end
		if user != nil
			user.decrement!(:num_lists, 1)		
		end
	end

	def Feed.added_venue_calibration(feed_id, venue_id)
		feed = Feed.find_by_id(feed_id)
		if feed != nil && venue_id != nil			
			feed.increment!(:num_venues, 1)
			venue_ids = feed.venue_ids
			feed.update_columns(venue_ids: venue_ids << venue_id)
			venue = Venue.find_by_id(venue_id)
			added_moment_count = venue.venue_comments.count || 0
			feed.increment!(:num_moments, added_moment_count)	
			feed.update_geo_mass_center
			feed.update_venue_attributes(venue)
		end
	end

	def Feed.removed_venue_calibration(feed_id, venue_id)
		feed = Feed.find_by_id(feed_id)
		venue_ids = feed.venue_ids
		venue_ids.delete(venue_id)
		feed.update_columns(venue_ids: venue_ids)
		feed.update_columns(num_moments: feed.venue_comments.count)
		feed.decrement!(:num_venues, 1)
		feed.update_geo_mass_center
	end

	def Feed.calibrate_feed_venue_activity
		feeds = Feed.all
		for feed in feeds
			for feed_venue in feed.feed_venues
				if Activity.where("feed_venue_id = ?", feed_venue.id).first.nil? == true	
					Activity.create!(:feed_id => feed_venue.feed.id, :activity_type => "added_venue", :feed_venue_id => feed_venue.id, :venue_id => feed_venue.venue_id, :user_id => feed_venue.user_id, :adjusted_sort_position => (feed_venue.created_at).to_i)
				end
			end
			feed.update_columns(num_venues: feed.feed_venues.count)
		end
	end

	def update_activity_feed_related_details
		self.activities.update_all(feed_name: self.name)
		self.activities.update_all(feed_color: self.feed_color)
	end

	def update_underlying_venues
		instagram_refresh_rate = 15 #minutes
		stale_venues = self.venues.where("last_instagram_pull_time < ?", Time.now-instagram_refresh_rate.minutes)
		for stale_venue in stale_venues		
			stale_venue.rebuild_cached_vc_feed
		end
		self.update_columns(latest_update_time: Time.now)
	end

	def comments
		#venue_ids = "SELECT venue_id FROM feed_venues WHERE feed_id = #{self.id}"
		comments = VenueComment.where("venue_id IN (?) AND adjusted_sort_position > ?", self.venue_ids, (Time.now-5.hours).to_i).order("adjusted_sort_position DESC")
	end

	def activity_of_the_day
		activity_ids = "SELECT activity_id FROM activity_feeds WHERE feed_id = #{self.id}"
		Activity.where("id IN (#{activity_ids}) AND created_at >= ?", Time.now-1.day).order("adjusted_sort_position DESC")
	end

	def latest_image_thumbnail_url
		venue_ids = "SELECT venue_id FROM feed_venues WHERE feed_id = #{self.id}"
		url = VenueComment.where("venue_id IN (#{venue_ids}) AND (NOW() - created_at) <= INTERVAL '1 DAY'").order("id DESC").first.try(:lowest_resolution_image_avaliable)
	end

	def is_venue_present?(v_id)
		FeedVenue.where("feed_id = ? AND venue_id = ?", self.id, v_id).any?
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
		#Formula: (v_weight*num_venues)+(m_weight*num_members)+(1/proximity_of_central_mass)

		city_bound = 20
		state_bound = 100
		country_bound = 1000
		continent_bound =  10000
		
		v_weight = 0.5
		m_weight = 0.1

		proximity = Geocoder::Calculations.distance_between([central_mass_latitude, central_mass_longitude], [user_lat, user_long], :units => :km)
		
		relevance_score = ((v_weight * num_venues) + (m_weight * num_users)) * 1/proximity
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
		#returns occurnaces of each category
		#FeedRecommendation.group(:category).count(:category)

		#returns categories that have at least 3 entries
		#FeedRecommendation.select("category as category").group("category").having("count(category) > ?", 3).pluck(:category)
		
		default_categories = ["parks", "bars", "coffee", "dog", "cat", "mouse", "house", "literature", "sports", "france", "germany", "netherlands", "russia", "travel", "cracerjacks", "watermellons"]
		used_categories = FeedRecommendation.where("category IS NOT NULL").uniq.pluck(:category)
		if used_categories.count == 0
			return default_categories
		else
			return used_categories
		end
	end

	def Feed.of_category(category, lat=40.741140, long=-73.981917)
		Feed.all.joins(list_category_entries: :list_category).where("list_categories.name = ?", category).order("feeds.central_mass_lonlat_geometry <-> st_point(#{long},#{lat})")
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
			point = "POINT(#{geo_mass_long} #{geo_mass_lat})"
			self.update_columns(central_mass_lonlat_geometry: point)
			self.update_columns(central_mass_lonlat_geography: point)			
			return [geo_mass_lat, geo_mass_long]
		else
			nil
		end
	end
	Feed.where("central_mass_lonlat_geometry is null AND (central_mass_latitude is not null and central_mass_longitude is not null)").each{|x| x.update_columns(central_mass_lonlat_geometry: "POINT(#{x.central_mass_longitude} #{x.central_mass_latitude})", central_mass_lonlat_geography: "POINT(#{x.central_mass_longitude} #{x.central_mass_latitude})")}

	def self.initial_recommendations(selected_categories)
		if selected_categories != nil
			FeedRecommendation.where("category IN (?) AND active IS TRUE", selected_categories)
		end
	end

	def venue_tweets
		venue_ids = "SELECT venue_id FROM feed_venues WHERE feed_id = #{self.id}"
		Tweet.where("venue_id IN (#{venue_ids})").order("timestamp DESC")
	end

	def recommended_venue_for_user(lat, long)
		user_location = [lat, long]
		search_box = Geokit::Bounds.from_point_and_radius(user_location, 1, :units => :kms)
		self.venues.in_bounds(search_box).where("rating IS NOT NULL").order("popularity_rank DESC").first
	end

	def assign_new_admin(user)
		self.update_columns(user_id: user.id)
		self.update_columns(user_details: user.partial)
	end


	def featured_venues
		self.venues.where("(NOW() - latest_posted_comment_time) <= INTERVAL '1 HOUR'").order("rating DESC LIMIT 10").shuffle
	end

	def Feed.populate_venue_ids_arrays
		for feed in Feed.all
			feed.update_columns(venue_ids: feed.feed_venues.pluck(:id))
		end
	end

end