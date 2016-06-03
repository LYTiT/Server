class VenueComment < ActiveRecord::Base
	include PgSearch
	#validates :comment, presence: true
	pg_search_scope :meta_search, #name and/or associated meta data
		against: :meta_data_vector,
		using: {
		  tsearch: {
		    dictionary: 'english',
		    #any_word: true,
		    #prefix: true,
		    tsvector_column: 'meta_data_vector'
		  }
		}           

	belongs_to :user
	belongs_to :venue

	has_many :flagged_comments, :dependent => :destroy
	has_many :comment_views, :dependent => :destroy
	has_many :meta_datas, :dependent => :destroy
	has_many :activities, :dependent => :destroy
	has_many :reported_objects, :dependent => :destroy

	#validate :comment_or_media

	before_destroy :deincrement_feed_moment_counts


	def VenueComment.cleanup_and_recalibration
		expired_venue_comment_ids = VenueComment.where("content_origin = ? AND (NOW() - time_wrapper) >= INTERVAL '1 DAY'", 'instagram').pluck(:id)
		associated_venue_ids = VenueComment.where("content_origin = ? AND (NOW() - time_wrapper) >= INTERVAL '1 DAY'", 'instagram').pluck(:venue_id)

		expired_activity_ids = Activity.where("venue_comment_id IN (?)", expired_venue_comment_ids).pluck(:id)
		Like.where("activity_id IN (?)", expired_activity_ids).delete_all
		ActivityComment.where("activity_id IN (?)", expired_activity_ids).delete_all
		ActivityFeed.where("activity_id IN (?)", expired_activity_ids).delete_all

		Activity.where("venue_comment_id IN (?)", expired_venue_comment_ids).delete_all
		MetaData.where("venue_comment_id IN (?)", expired_venue_comment_ids).delete_all
		VenueComment.where("content_origin = ? AND (NOW() - time_wrapper) >= INTERVAL '1 DAY'", 'instagram').delete_all

		Feed.joins(:feed_venues).where("venue_id IN (?)", associated_venue_ids).each{|feed| feed.update_columns(num_moments: feed.venue_comments.count)}
		Venue.where("id IN (?)", associated_venue_ids).update_all(updated_at: Time.now)
	end

	def VenueComment.daily_cleanup
		expired_activity_ids = Activity.where("activity_type != ? AND activity_type != ? AND created_at < ?", "added_venue", "new_topic", Time.now-24.hours).pluck(:id)
		ActivityComment.where("activity_id IN (?)", expired_activity_ids).delete_all
		ActivityFeed.where("activity_id IN (?)", expired_activity_ids).delete_all
		Activity.where("activity_type != ? AND activity_type != ? AND created_at < ?", "added_venue", "new_topic", Time.now-24.hours).delete_all
		VenueComment.where("created_at < ?", Time.now-24.hours).delete_all
	end

	def send_new_enlytened_notification
		if self.num_enlytened == 1 || (self.num_enlytened%5 == 0 && self.num_enlytened <= 20) || (self.num_enlytened%10 && self.num_enlytened > 20)
			payload = {
				:intended_for => self.user_id,
				:object_id => self.id,       
				:type => 'moment_enlytement_notification',
				:venue_comment_id => self.id,
				:media_type => self.lytit_post["media_type"],
				:media_dimensions => self.lytit_post["media_dimensions"],
				:image_url_1 => self.lytit_post["image_url_1"],
				:image_url_2 => self.lytit_post["image_url_2"],
				:image_url_3 => self.lytit_post["image_url_3"],
				:video_url_1 => self.lytit_post["video_url_1"],
				:video_url_2 => self.lytit_post["video_url_2"],
				:video_url_3 => self.lytit_post["video_url_3"],
				:venue_id => self.venue_details["id"],
				:venue_name => self.venue_details["name"],
				:venue_address => self.venue_details["address"],
				:venue_city => self.venue_details["city"],
				:venue_country => self.venue_details["country"],
				:latitude => self.venue_details["latitude"],
				:longitude => self.venue_details["longitude"],
				:timestamp => self.created_at.to_i,
				:content_origin => 'lytit',
				:num_enlytened => self.num_enlytened
			}

			type = "#{self.id}/enlytement"

			notification = Notification.where(type: type).first || self.store_new_notification(payload, user, type)

			payload[:notification_id] = notification.id

			if self.num_enlytened == 1
				preview = "Your post at #{self.venue_details["name"]} has enlytened a person!"
			elsif self.num_enlytened > 1 && self.num_enlytened <= 20
				preview = "You've enlytened 5 more people!"
			else
				preview = "You've enlytened 10 more people!"
			end

			if user.push_token && user.active == true
				count = Notification.where(user_id: user.id, read: false, deleted: false).count
				APNS.send_notification(user.push_token, { :priority =>10, :alert => preview, :content_available => 1, :other => payload, :badge => count})
			end
		end
	end

	def store_new_notification(payload, notification_user, type)
		notification = {
			:payload => payload,
			:gcm => notification_user.gcm_token.present?,
			:apns => notification_user.push_token.present?,
			:response => nil,
			:user_id => notification_user.id,
			:read => false,
			:message => type,
			:deleted => false
		}
		Notification.create(notification)
	end

	def increment_geo_views(country, city, latitude=0.0, longitude=0.0)
		#determining which continent the view is coming from
		viewer_position = [latitude, longitude]
		#[sw, ne]
		north_america_bounds = Geokit::Bounds.new(Geokit::LatLng.new(6.941979, -170.136810),Geokit::LatLng.new(73.557736,-52.539152))
		south_america_bounds = Geokit::Bounds.new(Geokit::LatLng.new(-56.307847, -102.636809),Geokit::LatLng.new(6.941979, -33.531578))
		europe_bounds = Geokit::Bounds.new(Geokit::LatLng.new(33.956071, -25.998513),Geokit::LatLng.new(71.631733, 43.739573)) 

		africa_bounds_1 = Geokit::Bounds.new(Geokit::LatLng.new(14.761126, -25.998513),Geokit::LatLng.new(36.978899, 33.956071))
		africa_bounds_2 = Geokit::Bounds.new(Geokit::LatLng.new(-36.405239, -25.998513),Geokit::LatLng.new(14.761126, 50.767733))
		
		asia_bounds_1 = Geokit::Bounds.new(Geokit::LatLng.new(33.956071, 43.739573),Geokit::LatLng.new(78.127094, -169.561336))
		asia_bounds_2 = Geokit::Bounds.new(Geokit::LatLng.new(14.761126, 34.438466),Geokit::LatLng.new(33.956071,-169.561336))
		asia_bounds_3 = Geokit::Bounds.new(Geokit::LatLng.new(-10.703582, 50.767733),Geokit::LatLng.new(14.761126,-169.561336))
		australia_bounds = Geokit::Bounds.new(Geokit::LatLng.new(-48.340006, 113.509112),Geokit::LatLng.new(-10.703582,-169.561336))

		if north_america_bounds.contains?(viewer_position)
			continent = "north_america"
		elsif south_america_bounds.contains?(viewer_position)
			continent = "south_america"
		elsif europe_bounds.contains?(viewer_position)
			continent = "europe"
		elsif africa_bounds_1.contains?(viewer_position) or africa_bounds_2.contains?(viewer_position)
			continent = "africa"
		elsif asia_bounds_1.contains?(viewer_position) or asia_bounds_2.contains?(viewer_position) or asia_bounds_3.contains?(viewer_position)
			continent = "asia"
		elsif australia_bounds.contains?(viewer_position)
			continent = "australia"
		else
			continent = nil
		end


		geo_views_hash = self.geo_views
		viewing_country = geo_views_hash[country]

		if viewing_country != nil
			viewing_city = geo_views_hash[country]["cities"][city]
			if viewing_city != nil
				geo_views_hash[country]["cities"][city] += 1
			else
				geo_views_hash[country]["cities"].merge!(city => 1)
			end			
			geo_views_hash[country]["total_views"] += 1
		else			
			geo_views_hash[country] = {"total_views" => 1, "cities" => {city => 1}, "continent" => continent}
		end

		self.update_columns(geo_views: geo_views_hash)
	end

	def add_fake_geo_views(num_cycles=20)
		geos = [["United States", "New York"], ["United States", "Los Angeles"], ["United States", "Chicago"], ["United States", "Dallas"], ["China", "Beijing"], ["France", "Paris"], ["Germany", "Berlin"], ["Brazil", "Rio De Janeiro"]]

		for i in 0...num_cycles
			selection = geos[rand(geos.count)]
			increment_geo_views(selection.first, selection.last)
		end
	end

	def deincrement_feed_moment_counts
		begin
			self.venue.feeds.update_all("num_moments = num_moments-1")
		rescue
			p "Something went wrong"
		end
	end

	def comment_or_media
		if self.comment.blank? and (self.image_url_3.blank? && self.video_url_3.blank?)
			errors.add(:comment, 'or image is required')
		end
	end

	def lowest_resolution_image_avaliable
		begin
			self.image_url_1 || self.image_url_2
		rescue
			nil
		end
	end

	def username_for_trending_venue_view
		if self.content_origin == "instagram"
			self.thirdparty_username
		else
			self.user.name
		end
	end

	def is_viewed?(user)
		CommentView.find_by_user_id_and_venue_comment_id(user.id, self.id).present?
	end

	def total_views
		CommentView.where(venue_comment_id: self.id).count
	end

	def populate_total_views
		update_columns(views: total_views)
	end

	def update_views
		current = self.views
		update_columns(views: (current + 1))
	end

	def total_adj_views
		self.adj_views
	end

	def calculate_adj_view
		time = Time.now
		comment_time = self.created_at
		time_delta = ((time - comment_time) / 1.minute) / (LumenConstants.views_halflife)
		adjusted_view = 2.0 ** (-time_delta)

		previous = self.adj_views
		update_columns(adj_views: (adjusted_view + previous).round(4))
	end

	#We need to omit CommentViews generated by the user of the VenueComment
	def populate_adj_views
		total = 0
		if self.media_type == 'text'
			total = 1
		else
			views = CommentView.where("venue_comment_id = ? and user_id != ?", self.id, self.user_id)
			views.each {|view| total += 2 ** ((- (view.created_at - self.created_at) / 1.minute) / (LumenConstants.views_halflife))}
		end
		update_columns(adj_views: total.round(4))
		total
	end


	def set_offset_created_at
		#note that offset time will still be stored in UTC, disregard the timezone
		if venue != nil
			offset = created_at.in_time_zone(venue.time_zone).utc_offset
			offset_time = created_at + offset
			update_columns(offset_created_at: offset_time)
		end
	end

	def self.get_comments_for_cluster(venue_ids)
		VenueComment.where("venue_id IN (?) AND (NOW() - created_at) <= INTERVAL '1 DAY'", venue_ids).includes(:venue).order("time_wrapper desc")
	end

	def self.map_instagrams_to_hashes_and_convert(instagrams)
		self.convert_bulk_instagrams_to_vcs(instagrams.map!(&:to_hash), nil)		
	end

	def VenueComment.convert_new_social_media_to_vcs(instagram_hashes, tweets, origin_venue)
		VenueComment.convert_bulk_instagrams_to_vcs(instagram_hashes, origin_venue)
		Tweet.bulk_conversion(tweets, origin_venue, nil, nil, nil, nil)
	end

	def self.bulk_convert_instagram_hashie_to_vc(instagrams, origin_venue)
		for instagram in instagrams
			self.convert_instagram_hashie_to_vc(instagram, origin_venue)
		end
	end

	def self.convert_bulk_instagrams_to_vcs(instagram_hashes, origin_venue)
		#instagram_hashes.each{|instagram_hash| VenueComment.create_vc_from_instagram(instagram_hash, origin_venue, nil)}
		num_instagrams = instagram_hashes.count
		last = false
		instagram_hashes.each_with_index do |instagram_hash, index|
			if (index+1) == num_instagrams
				last = true
			end
			VenueComment.create_vc_from_instagram(instagram_hash, origin_venue, nil, last)
		end
	end


	def self.create_vc_from_instagram(instagram_hash, origin_venue, vortex, last_of_batch)
		#Vortex pulls do not have an associated venue, thus must determine on an instagram by instagram basis		
		if origin_venue == nil
			origin_venue = Venue.validate_venue(instagram_hash["location"]["name"], instagram_hash["location"]["latitude"], instagram_hash["location"]["longitude"], instagram_hash["location"]["id"], vortex)
			if origin_venue == nil
				return nil
			end
		end
		created_time = DateTime.strptime(instagram_hash["created_time"],'%s')

		if origin_venue.in_timespan?("open_hours", created_time)
			#Instagram sometimes returns posts outside the vortex radius, we filter them out
			if vortex != nil && origin_venue != nil
				if origin_venue.distance_from([vortex.latitude, vortex.longitude]) * 1609.34 > 6000
					return nil
				else
					if origin_venue.city == nil
						origin_venue.update_columns(city: vortex.city)
					end

					if origin_venue.country == nil
						origin_venue.update_columns(country: vortex.country)
					end
				end
			end

			presence = VenueComment.find_by_instagram_id(instagram_hash["id"])
			vc = nil			

			if presence == nil
				vc = VenueComment.create!(:entry_type => "instagram", :venue_id => origin_venue.id, :venue_details => origin_venue.partial, :instagram => VenueComment.create_instagram_partial(instagram_hash), :instagram_id => instagram_hash["id"], :adjusted_sort_position => created_time.to_i) rescue nil
			end

			if vc != nil
				#Venue method
				if origin_venue.latest_posted_comment_time == nil or origin_venue.latest_posted_comment_time < created_time
					origin_venue.update_columns(latest_posted_comment_time: created_time)
					origin_venue.update_columns(last_instagram_post: vc["instagram"]["instagram_id"])
				end

				if (origin_venue.last_instagram_pull_time != nil and origin_venue.last_instagram_pull_time < created_time) || vortex != nil
					origin_venue.update_columns(last_instagram_pull_time: Time.now-10.minutes)
				end

				#Further instagram related methods
				#instagram_tags = instagram_hash["tags"]
				#instagram_captions = instagram_hash["caption"]["text"].split rescue nil
				#vc.delay.extract_instagram_meta_data(instagram_tags, instagram_captions)

				origin_venue.delay.update_descriptives_from_instagram(instagram_hash)

				#Feed related methods
				#origin_venue.feeds.update_all(new_media_present: true)
				#origin_venue.feeds.update_all(latest_content_time: created_time)
				origin_venue.feeds.update_all("num_moments = num_moments+1")

				#Venue LYTiT ratings related methods
				#if venue is currently popular the probability of an assigned lytit vote is 100%, else 75% (that's the rand(3)).
				#if a venue has popular hours but not open hours, we treat them as open hours. Thus assign lyt only if venue is popular.
				if origin_venue.in_timespan?("popular_hours", created_time) == true 
					origin_venue.update_rating(true)
				elsif (origin_venue.in_timespan?("popular_hours", created_time) ? 1:0) + rand(4) > 0 && origin_venue.open_hours["NA"] == nil
					origin_venue.update_rating(true)
				else
					p "Comment is most likely not live. Vote not assigend."
				end
					
				#newly created venues for instagrams for vortices will have an instagram id but not a last instagram pull time.
				#to prevent a redundent set_instagram_location_id opperation we assign a last instagram pull time.

				if last_of_batch == true
					#origin_venue.set_last_venue_comment_details(vc)
					origin_venue.update_columns(last_instagram_id: vc.instagram["instagram_id"])
					origin_venue.update_featured_comment(vc)
					origin_venue.set_top_tags

					if origin_venue.moment_request_details != {}
						if MomentRequest.fulfilled_by_post(origin_venue.moment_request_details["created_at"], "instagram")
							MomentRequest.find_by_id(origin_venue.moment_request_details["id"]).notify_requesters_of_response(vc)
							origin_venue.update_columns(moment_request_details: {})
						end
					end
				end
			else
				nil
			end
		end
	end

	def self.convert_raw_instagram_params_to_vc(instagram_params, origin_venue_id)
		presence = VenueComment.find_by_instagram_id(instagram_params["instagram_id"])
		if presence == nil
			if Venue.name_is_proper?(instagram_params["venue_name"].titlecase) == true && (instagram_params["latitude"] != nil && instagram_params["longitude"] != nil)
				if origin_venue_id == nil	
					#venue = Venue.fetch_venues_for_instagram_pull(instagram_params["venue_name"], instagram_params["latitude"], instagram_params["longitude"], instagram_params["instagram_location_id"], nil)
					venue = Venue.validate_venue(instagram_params["venue_name"], instagram_params["latitude"], instagram_params["longitude"], instagram_params["instagram_location_id"], nil)
				else
					venue = Venue.find_by_id(origin_venue_id)
				end

				vc = VenueComment.create!(:entry_type => "instagram", :venue_id => venue.id, :venue_details => venue.partial, :instagram => {:instagram_user => {:name => instagram_params["thirdparty_username"], 
					:profile_image_url => instagram_params["profile_image_url"], :instagram_id => instagram_params["thirdparty_user_id"]}, :instagram_id => instagram_params["instagram_id"], 
					:media_type => instagram_params["media_type"], :media_dimensions => instagram_params["media_dimensions"], :image_url_1 => instagram_params["image_url_1"], :image_url_2 => instagram_params["image_url_2"], 
					:image_url_3 => instagram_params["image_url_3"], :video_url_1 => instagram_params["video_url_1"], :video_url_2 => instagram_params["video_url_2"], :video_url_3 =>  instagram_params["video_url_3"],
					:created_at => Time.parse(instagram_params["created_at"])}, :adjusted_sort_position => Time.parse(instagram_params["created_at"]).to_i)
				
				return vc
			else
				return nil
			end
		else
			return presence
		end
	end

	def self.convert_instagram_hashie_to_vc(instagram, origin_venue)
		instagram_hash = instagram.to_hash
		vc = VenueComment.create!(:entry_type => "instagram", :venue_id => origin_venue.id, :venue_details => origin_venue.partial, :instagram => VenueComment.create_instagram_partial(instagram_hash), :adjusted_sort_position => created_time.to_i)
		VenueComment.delay.post_vc_creation_calibration(origin_venue, vc, instagram)
	end	


	def self.post_instagram_vc_creation_calibration(origin_venue, vc, instagram)
		instagram_created_time = DateTime.strptime("#{instagram.created_time}",'%s')

		if origin_venue.latest_posted_comment_time == nil or origin_venue.latest_posted_comment_time < instagram_created_time
			origin_venue.update_columns(latest_posted_comment_time: instagram_created_time)
			origin_venue.update_columns(last_instagram_post: instagram_id)
		end

		if (origin_venue.last_instagram_pull_time != nil and origin_venue.last_instagram_pull_time < instagram_created_time) || vortex != nil
			origin_venue.update_columns(last_instagram_pull_time: Time.now-10.minutes)
		end

		#Meta data methods
		instagram_tags = instagram.tags
		instagram_captions = instagram.caption.text.split rescue nil
		vc.extract_instagram_meta_data(instagram_tags, instagram_captions)

		origin_venue.feeds.update_all("num_moments = num_moments+1")

		#Venue LYTiT ratings related methods
		if vc.is_live? == true
			#vote = LytitVote.create!(:value => 1, :venue_id => origin_venue.id, :user_id => nil, :venue_rating => origin_venue.rating ? origin_venue.rating : 0, 
			#								:prime => 0.0, :raw_value => 1.0, :time_wrapper => instagram_created_time)
			#origin_venue.update_r_up_votes(instagram_created_time)
			origin_venue.update_rating(true)
			origin_venue.update_columns(latest_rating_update_time: Time.now)
		end

	end

	def VenueComment.create_instagram_partial(instagram_hash)
		if instagram_hash["type"] == "video"
			video_url_1 = instagram_hash["videos"]["low_bandwidth"]["url"]
			video_url_2 = instagram_hash["videos"]["low_resolution"]["url"]
			video_url_3 = instagram_hash["videos"]["standard_resolution"]["url"]
			media_dimensions = instagram_hash["videos"]["standard_resolution"]["width"].to_s+"x"+instagram_hash["images"]["standard_resolution"]["height"].to_s
		else
			video_url_1 = nil
			video_url_2 = nil
			video_url_3 = nil
			media_dimensions = instagram_hash["images"]["standard_resolution"]["width"].to_s+"x"+instagram_hash["images"]["standard_resolution"]["height"].to_s
		end
		partial = {:instagram_user => {:name => instagram_hash["user"]["username"], :profile_image_url => instagram_hash["user"]["profile_picture"], 
			:instagram_id => instagram_hash["user"]["id"]}, :instagram_id => instagram_hash["id"], :media_type => instagram_hash["type"], 
			:media_dimensions => media_dimensions, :image_url_1 => instagram_hash["images"]["thumbnail"]["url"], 
			:image_url_2 => instagram_hash["images"]["low_resolution"]["url"], :image_url_3 => instagram_hash["images"]["standard_resolution"]["url"], 
			:video_url_1 => video_url_1, :video_url_2 => video_url_2, :video_url_3 => video_url_3, :created_at => DateTime.strptime(instagram_hash["created_time"],'%s')}
	end




	def extract_instagram_meta_data(instagram_tags, instagram_captions)
		if venue != nil
			inst_hashtags = instagram_tags
			inst_comment = instagram_captions
			#inst_meta_data = (inst_hashtags << inst_comment).flatten.compact

			if inst_hashtags != nil and inst_hashtags.count != 0
				inst_hashtags.each do |data|
					if data.length > 2 && (data.include?("inst") == false && data.include?("gram") == false && data.include?("like") == false)
						lookup = MetaData.where("meta = ? AND venue_id = ?", data, venue_id).first
						if lookup == nil
							venue_meta_data = MetaData.create!(:venue_id => venue_id, :venue_comment_id => id, :meta => data, :clean_meta => nil) #rescue MetaData.increment_relevance_score(data, venue_id)
						else
							lookup.increment_relevance_score
						end
					end
				end
			end
			self.touch
			venue.set_top_tags
		end
	end

	def extract_venue_comment_meta_data
		text = self.lytit_post["comment"].split rescue []
		junk_words = ["the", "their", "there", "yes", "you", "are", "when", "why", "what", "lets", "this", "got", "put", "such", "much", "ask", "with", "where", "each", "all", "from", "bad", "not", "for", "our", "finally"]
=begin	
		junk_words_2 = ["a", "about", "above", "above", "across", "after", "afterwards", "again", "against", "all", "almost", "alone", "along", "already", "also","although","always","am","among", "amongst", "amoungst", "amount",  
		 	"an", "and", "another", "any","anyhow","anyone","anything","anyway", "anywhere", "are", "around", "as",  "at", "back","be","became", "because","become","becomes", "becoming", "been", "before", "beforehand", 
		 	"behind", "being", "below", "beside", "besides", "between", "beyond", "bill", "both", "bottom","but", "by", "call", "can", "cannot", "cant", "co", "con", "could", "couldnt", "cry", "de", "describe", "detail", "do", 
		 	"done", "down", "due", "during", "each", "eg", "eight", "either", "eleven","else", "elsewhere", "empty", "enough", "etc", "even", "ever", "every", "everyone", "everything", "everywhere", "except", "few", "fifteen", 
		 	"fify", "fill", "find", "fire", "first", "five", "for", "former", "formerly", "forty", "found", "four", "from", "front", "full", "further", "get", "give", "go", "had", "has", "hasnt", "have", "he", "hence", "her", 
		 	"here", "hereafter", "hereby", "herein", "hereupon", "hers", "herself", "him", "himself", "his", "how", "however", "hundred", "ie", "if", "in", "inc", "indeed", "interest", "into", "is", "it", "its", "itself", "keep", 
		 	"last", "latter", "latterly", "least", "less", "ltd", "made", "many", "may", "me", "meanwhile", "might", "mill", "mine", "more", "moreover", "most", "mostly", "move", "much", "must", "my", "myself", "name", "namely", 
		 	"neither", "never", "nevertheless", "next", "nine", "no", "nobody", "none", "noone", "nor", "not", "nothing", "now", "nowhere", "of", "off", "often", "on", "once", "one", "only", "onto", "or", "other", "others", 
		 	"otherwise", "our", "ours", "ourselves", "out", "over", "own","part", "per", "perhaps", "please", "put", "rather", "re", "same", "see", "seem", "seemed", "seeming", "seems", "serious", "several", "she", "should", 
		 	"show", "side", "since", "sincere", "six", "sixty", "so", "some", "somehow", "someone", "something", "sometime", "sometimes", "somewhere", "still", "such", "system", "take", "ten", "than", "that", "the", "their", 
		 	"them", "themselves", "then", "thence", "there", "thereafter", "thereby", "therefore", "therein", "thereupon", "these", "they", "thickv", "thin", "third", "this", "those", "though", "three", "through", "throughout", 
		 	"thru", "thus", "to", "together", "too", "top", "toward", "towards", "twelve", "twenty", "two", "un", "under", "until", "up", "upon", "us", "very", "via", "was", "we", "well", "were", "what", "whatever", "when",
		 	 "whence", "whenever", "where", "whereafter", "whereas", "whereby", "wherein", "whereupon", "wherever", "whether", "which", "while", "whither", "who", "whoever", "whole", "whom", "whose", "why", "will", "with", 
		 	 "within", "without", "would", "yet", "you", "your", "yours", "yourself", "yourselves", "the"]
=end		 	 

		text.each do |data|
			#sub_entries are for CamelCase handling if any
			sub_entries = data.split /(?=[A-Z])/
			sub_entries.each do |sub_entry|
				clean_data = sub_entry.downcase.gsub(/[^0-9A-Za-z]/, '')
				puts "Dirty Data: #{sub_entry}...Clean Data: #{clean_data}"
				if clean_data.length>2 && junk_words.include?(clean_data) == false
					extra_clean_data = remove_meta_data_prefixes_suffixes(clean_data)
					lookup = MetaData.where("meta = ? AND venue_id = ?", extra_clean_data, venue_id).first
					if lookup == nil
						venue_meta_data = MetaData.create!(:venue_id => venue_id, :venue_comment_id => id, :meta => clean_data, :clean_meta => extra_clean_data)
					else
						lookup.increment_relevance_score					
					end
				end
			end
		end
		self.touch
		venue.set_top_tags
	end

	def remove_meta_data_prefixes_suffixes(data)
		prefixes = ["anti", "de", "dis", "en", "fore", "in", "im", "ir", "inter", "mid", "mis", "non", "over", "pre", "re", "semi", "sub", "super", "trans", "un", "under"]
		suffixes = ["able", "ible", "al", "ial", "ed", "en", "er", "est", "ful", "ic", "ing", "ion", "tion", "ation", "ition", "ity", "ty", "ive", "ative", "itive", "less", "ly", "ment", "ness", "ous", "eous", "ious", "y"]		  
		
		no_prefix_suffix_data = nil
		if data.length > 5
			for prefix in prefixes
				no_prefix_data = data
				prefix_len = prefix.length
				data_len = data.length

				if data_len > prefix_len and data[0..prefix_len-1] == prefix
					no_prefix_data = data[(prefix_len)..data_len+1]
					break
				end
			end

			if no_prefix_data.length > 6
				for suffix in suffixes
					suffix_len = suffix.length
					no_prefix_data_len = no_prefix_data.length
					no_prefix_suffix_data = no_prefix_data

					if no_prefix_data_len > suffix_len and no_prefix_data[(no_prefix_data_len-suffix_len)..no_prefix_data_len] == suffix
						no_prefix_suffix_data = no_prefix_data[0..(no_prefix_data_len-suffix_len)-1]
						break
					end
				end
			else
				clean_data = no_prefix_data
			end

			if no_prefix_suffix_data != nil
				clean_data = no_prefix_suffix_data
			end

		else
			clean_data = data
		end					
		return clean_data
	end

	#These methods are for proper key selection for get_surrounding_posts since hybrid arrays of instagram as well as LYTiT Venue Comment objects can exist there
	def self.implicit_id(post)
		if post.is_a?(Hash)
			nil
		else
			post.id
		end
	end

	def self.implicit_instagram_id(post)
		if post.is_a?(Hash)
			post["id"]
		else
			post.instagram_id
		end
	end

	def self.implicit_instagram_location_id(post)
		if post.is_a?(Hash)
			post["location"]["id"]
		else
			post.venue.instagram_location_id
		end
	end	

	def self.implicit_media_type(post)
		if post.is_a?(Hash)
			post["type"]
		else
			post.media_type
		end
	end

	def self.implicit_image_url_1(post)
		if post.is_a?(Hash)
			post["images"]["thumbnail"]["url"]
		else
			post.image_url_1
		end
	end

	def self.implicit_image_url_2(post)
		if post.is_a?(Hash)
			post["images"]["low_resolution"]["url"] || post["images"]["standard_resolution"]["url"]
		else
			post.image_url_2
		end
	end

	def self.implicit_image_url_3(post)
		if post.is_a?(Hash)
			post["images"]["standard_resolution"]["url"]
		else
			post.image_url_3
		end
	end

	def self.implicit_video_url_1(post)
		if post.is_a?(Hash)
			if post["type"] == "video"
				post["videos"]["low_bandwidth"]["url"]
			else
				nil
			end
		else
			post.video_url_1
		end
	end

	def self.implicit_video_url_2(post)
		if post.is_a?(Hash)
			if post["type"] == "video"
				post["videos"]["low_resolution"]["url"]
			else
				nil
			end
		else
			post.video_url_2
		end
	end

	def self.implicit_video_url_3(post)
		if post.is_a?(Hash)
			if post["type"] == "video"
				post["videos"]["standard_resolution"]["url"]
			else
				nil
			end
		else
			post.video_url_3
		end
	end

	def self.implicit_venue_id(post, origin_venue)
		if origin_venue != nil
			origin_venue.id
		elsif post.is_a?(Hash)
			nil
		else
			post.venue_id
		end
	end

	def self.implicit_venue_name(post)
		if post.is_a?(Hash)
			post["location"]["name"]
		else
			post.venue.name
		end
	end

	def self.implicit_venue_latitude(post)
		if post.is_a?(Hash)
			post["location"]["latitude"]
		else
			post.venue.latitude
		end
	end

	def self.implicit_venue_longitude(post)
		if post.is_a?(Hash)
			post["location"]["longitude"]
		else
			post.venue.longitude
		end
	end

	def self.implicit_created_at(post)
		if post.is_a?(Hash)
			DateTime.strptime(post["created_time"],'%s')
		else
			post.time_wrapper
		end
	end

	def self.implicit_content_origin(post)
		if post.is_a?(Hash)
			"instagram"
		else
			post.content_origin
		end
	end

	def self.thirdparty_username(post)
		if post.is_a?(Hash)
			post["user"]["username"]
		else
			post.thirdparty_username
		end
	end

	def self.meta_search_results(v_id, query)
		meta_vc_ids = MetaData.where("venue_id = ?", v_id).search(query).pluck(:venue_comment_id)
		#query = '%'+query.downcase+'%'
		#meta_vc_ids = "SELECT venue_comment_id FROM meta_data WHERE venue_id = #{v_id} AND meta LIKE '#{query}'"
		if meta_vc_ids != nil
			VenueComment.where("id IN (?)", meta_vc_ids).order("time_wrapper DESC")
		else
			nil
		end
	end

	def VenueComment.thirdparty_created_at(content)
		if content["created_time"] != nil
			DateTime.strptime(content["created_time"],'%s')
		else
			Time.parse(content[:created_at])
		end
	end

	def evaluate(user_id, enlytened, city, country, latitude, longitude)
		evaluater_user_ids = self.evaluater_user_ids
		if enlytened == true
			self.increment!(:num_enlytened, 1)
			self.user.increment!(:num_bolts, 1)
			self.increment_geo_views(country, city, latitude, longitude)
			evaluater_user_ids[user_id] = "enlytened"
			self.send_new_enlytened_notification
		else
			evaluater_user_ids[user_id] = "not_enlytened"
		end 
		self.update_columns(evaluater_user_ids: evaluater_user_ids)
	end

	def VenueComment.assign_views_to_posts(only_on_admin=true)
		if only_on_admin == true
			lytit_posts = VenueComment.where("content_origin = ?", "lytit_post").joins(:venue).where("rating IS NOT NULL").joins(:user).where("role_id = 1")
		else			
			lytit_posts = VenueComment.where("content_origin = ?", "lytit_post").joins(:venue).where("rating IS NOT NULL")
		end
		lytit_posts.each{|lytit_post| lytit_post.view_generator}
	end

	def view_generator(total_sim_user_base=10000)
		#NEEDS TO TAKE INTO CONSIDERATION LOCAL TIME OF DAY
		num_views = self.num_enlytened
		num_surrounding_users = User.where("latitude IS NOT NULL").close_to(venue.latitude, venue.longitude, 20000).count		
		total_users = User.where("latitude IS NOT NULL").count

		num_simulated_nearby_users = (total_sim_user_base * (num_surrounding_users.to_f/(total_users.to_f+1.0))) || 0
		num_preceeding_posts = venue.venue_comments.where("adjusted_sort_position > ?", self.adjusted_sort_position).count

		venue_rating = venue.rating || 0

		#probability of receiving a view *
		#a weighting of rating, surrounding lyts, preceeding posts, num surrounded users - surrounding user views
		average_num_views_per_interval_local = (((1.0/num_surrounding_lyts)*rating.round(1)*(1.0-0.25*num_preceeding_posts/3)) * num_simulated_nearby_users)*#time of day scale
		
		#United States =>{[New York, Los Angeles, San Francisco, 111]}
		poisson = Croupier::Distributions.poisson(:lambda => average_num_views_per_interval)
		num_new_views = poisson.generate_sample(1)
		p num_new_views
		for i in 1..num_new_views
			self.user.increment!(:num_bolts, 1)

			nearby_venue = Venue.close_to(venue.latitude, venue.longitude, 20000).first
			faraway_venue = Venue.far_from(venue.latitude, venue.longitude, 20000).offset(rand(1000)).first rescue Venue.far_from(venue.latitude, venue.longitude, 20000).first
			selected_venue = (rand(99) < 96 ? nearby_venue : faraway_venue) 
			country = selected_venue.country
			city = selected_venue.city
			lytit_post.increment_geo_views(country, city)
		end
	end




=begin



		venue = self.venue
		venue_rating = venue.rating || (rand(5) >=3 ? 0 : 0.0005)

		num_surrounding_users = User.where("latitude IS NOT NULL").close_to(venue.latitude, venue.longitude, 20000).count
		total_users = User.where("latitude IS NOT NULL").count

		num_simulated_nearby_users = (total_sim_user_base * (num_surrounding_users.to_f/(total_users.to_f+1.0))

		#total_sim_user_base * (num_surrounding_users.to_f/(total_users.to_f+1.0)) - lytit_post.views) * venue_rating/1000.0 + ((rand(2) == 0 ? 1 : -1) * rand(10))

		num_preceeding_posts = venue.venue_comments.where("adjusted_sort_position > ?", self.adjusted_sort_position).count

		#num_simulted_views = (num_simulated_users * (1 - num_preceeding_posts*0.01)).floor


		normal_dist = Rubystats::NormalDistribution.new(mean, sd)
		normal = Croupier::Distributions.normal(:mu=>0.66, :sigma=>0.1)
		success = normal.generate_sample(1)
		#assume probability of a view is normally distributed. Select a sample and plug into geometric. success = probability of no 
		geometric = Croupier::Distributions.geometric(:success=>success)
		x = normal_dist.rng.floor

		#distribution of views in 10 minute interval given average number of views in set interval = lambda. Labmda is a function of venue
		#rating, post position, venue location, num outstanding views receieved, {and venue popularity maybe}
		poisson = Croupier::Distributions.poisson(:lambda=>1)

		num_new_views = possion.generate_sample(1)

		if x > 0
			num_new_views = x

		end



		for i in 1..num_simulted_views
			lytit_post.user.increment!(:num_bolts, 1)

			nearby_venue = Venue.close_to(venue.latitude, venue.longitude, 20000).first
			faraway_venue = Venue.far_from(venue.latitude, venue.longitude, 20000).offset(rand(1000)).first rescue Venue.far_from(venue.latitude, venue.longitude, 20000).first
			selected_venue = (rand(99) < 96 ? nearby_venue : faraway_venue) 
			country = selected_venue.country
			city = selected_venue.city
			lytit_post.increment_geo_views(country, city)

	  		view = CommentView.delay(run_at: rand(900).seconds.from_now).create!(:venue_comment_id => lytit_post.id, :user_id => 1)
		end
=end
			
end




