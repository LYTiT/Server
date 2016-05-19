class User < ActiveRecord::Base
  include Clearance::User

  attr_accessor :password_confirmation

  validates_uniqueness_of :name, :case_sensitive => false
  validates :name, presence: true, format: { with: /\A(^@?(\w){1,40}$)\Z/i}
  #validates :venues, presence: true, if: Proc.new {|user| user.role.try(:name) == "Venue Manager"}
  #validates :venues, absence: true, if: Proc.new {|user| user.role.try(:name) != "Venue Manager"}
  validates :email, presence: true, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
  validates_length_of :password, :minimum => 8, unless: :skip_password_validation?

  #has_many :venue_ratings, :dependent => :destroy
  has_many :venue_comments, :dependent => :destroy
  #has_many :flagged_comments, :dependent => :destroy

  has_many :announcement_users, :dependent => :destroy
  has_many :announcements, through: :announcement_users

  has_many :likes, foreign_key: "liker_id", dependent: :destroy
  has_many :liked_users, through: :likes, source: :liked
  has_many :likes_received, foreign_key: "liked_id", class_name: "Like", dependent: :destroy
  has_many :likers, through: :likes_received, source: :liker

  has_many :feed_invitations, foreign_key: "inviter_id", dependent: :destroy
  has_many :invitee_users, through: :feed_invitations, source: :invitee
  has_many :received_feed_invitations, foreign_key: "invitee_id", class_name: "FeedInvitation", dependent: :destroy
  has_many :inviters, through: :received_feed_invitations, source: :inviter

  has_many :feed_users, :dependent => :destroy
  has_many :feeds, through: :feed_users
  has_many :instagram_auth_tokens

  has_many :activities, :dependent => :destroy
  has_many :activity_comments, :dependent => :destroy

  has_one :support_issue, :dependent => :destroy
  has_many :support_messages, :dependent => :destroy
  has_many :event_organizers, :dependent => :destroy
  has_many :event_announcements, :dependent => :destroy

  has_many :favorite_venues, :dependent => :destroy
  has_many :moment_requests, :dependent => :destroy

  has_many :reported_objects, :dependent => :destroy

  has_many :moment_request_users, :dependent => :destroy
  has_many :feed_join_requests, :dependent => :destroy

  belongs_to :role

  before_save :ensure_authentication_token
  before_save :generate_confirmation_token_for_venue_manager
  before_save :generate_user_confirmation_token
  after_save :notify_venue_managers

  scope :close_to, -> (latitude, longitude, distance_in_meters = 2000) {
    where(%{
      ST_DWithin( users.lonlat_geography, ST_GeographyFromText('SRID=4326;POINT(%f %f)'), %d )
    } % [longitude, latitude, distance_in_meters])
  }


  #I.
  def partial
    {:id => self.id, :name => self.name, :facebook_id => self.facebook_id, :facebook_name => self.facebook_name, :profile_image_url => self.profile_image_url, :profile_description =>  self.profile_description, :is_verified => self.is_verified}
  end

  def can_post?
    #The more report occurances, the longer the time out.
    num_reports = self.violations.values.count("Reported Post")
    if num_reports > 0
      time_since_latest_report = Time.now - violations.select{|k, v| v == "Reported Post"}.keys[0]
      if time_since_latest_report < num_reports*2.hours
        retrun "Your posting privileges are currently suspended due to having posted innapropriate content. You may post again in #{((num_reports*2.hours-time_since_latest_report)/60.0).to_i} minutes."
      else
        nil
      end      
    else
      nil
    end
  end

  def update_location(lat, long)
    self.update_columns(latitude: lat)
    self.update_columns(longitude: long)
    point = "POINT(#{long} #{lat})"
    self.update_columns(lonlat_geometry: point)
    self.update_columns(lonlat_geography: point)
  end

  def nearest_neighbors(count=10, latitude=nil, longitude=nil)
    lat = latitude || self.longitude 
    long = longitude || self.longitude 
    User.where("lonlat_geometry IS NOT NULL").order("lonlat_geometry <-> st_point(#{self.longitude},#{self.longitude})").limit(count)
    #User.where("lonlat_geometry IS NOT NULL AND (lonlat_geometry <-> st_point(#{self.longitude},#{self.latitude})) * 100000 >= 400").order("lonlat_geometry <-> st_point(#{self.longitude},#{self.latitude})").limit(count)
  end

  def update_feeds_and_favorites
    update_user_feeds
    update_favorite_venues
  end

  def update_user_feeds
    update_interval = 15 #minutes

    top_user_feed_ids = "SELECT feed_id FROM feed_users WHERE user_id = #{self.id} ORDER BY interest_score DESC LIMIT 5"
    user_feeds = Feed.where("id IN (#{top_user_feed_ids})")

    for feed in user_feeds
      if feed.latest_update_time == nil or (feed.latest_update_time < (Time.now - update_interval.minutes))
        feed.update_underlying_venues
      end
    end
  end

  def update_favorite_venues
    instagram_refresh_rate = 15 #minutes
    favorite_venue_ids = "SELECT venue_id FROM favorite_venues WHERE user_id = #{self.id}"
    favorite_stale_venues = Venue.where("id IN (#{favorite_venue_ids}) AND last_instagram_pull_time < ?", Time.now-instagram_refresh_rate.minutes).limit(5)
    for stale_venue in favorite_stale_venues
      stale_venue.rebuild_cached_vc_feed
    end
  end

  def list_news_feed
    user_list_ids = "SELECT id FROM feed_users WHERE user_id = #{self.id}"
    Activity.where("feed_id IN (#{user_list_ids})").order("adjusted_sort_position DESC")
  end

  def top_interests(count=10)
    category_interests = self.interests["venue_categories"] || {}
    decriptive_interests = self.interests["descriptives"] || {}

    top_categories = Hash[category_interests.sort_by { |k,v| -v["weight"] }.select{|k,v| v["weight"] > 5.0}[0..(count/2-1)]].keys

    num_descripitives = count - top_categories.length

    top_descriptives = Hash[decriptive_interests.sort_by { |k,v| -v["weight"] }.select{|k,v| v["weight"] > 5.0}[0..num_descripitives]].keys

    return (top_categories+top_descriptives).shuffle
  end

  def suggested_interests
    ["skateboard", "sports" ,"nightlife", "justin bieber", "cake", "basketball", "music", "theater", "football",
      "art", "game of thrones", "movies", "cars", "science", "nature", "running", "technology", "beer"]

  end

  def update_interests(source, details)
    if details == "searched_venue"
      update_user_venue_categories(source, nil, nil)
      update_user_descriptives(source, nil, nil)  
    elsif details == "favorited_venue"
      update_user_venue_categories(nil, source, nil)
      update_user_descriptives(nil, source, nil)
    else
      update_user_venue_categories(nil, nil, source)
      update_user_descriptives(nil, nil, source)
    end
  end

  def update_user_venue_categories(venue, favorite_venue=nil, list=nil)
    if venue != nil
      tracker_key = "searched_venue_ids"
      added_value = 1.0
      source = venue
    elsif favorite_venue != nil
      tracker_key = "favorite_venue_ids"
      added_value = 10.0
      source = favorite_venue
    else
      tracker_key = "joined_list_ids"
      added_value = 5.0
      source = list
    end

    interests_hash = self.interests
    interest_categories_hash = self.interests["venue_categories"] || {}
    
    if list != nil
      source_categories = source.venue_attributes["venue_categories"] || {}
    else
      source_categories = source.categories
    end

    source_categories.each do |label, category|
      if list != nil
        category = label.downcase
      else
        category = category.downcase
      end
      if interest_categories_hash != nil and interest_categories_hash[category] != nil
        underlying_source_ids = interest_categories_hash[category][tracker_key].to_a
        previous_score = interest_categories_hash[category]["weight"].to_f
        if underlying_source_ids != [] and underlying_source_ids.include?(source.id) == true
          interest_categories_hash[category]["weight"] = previous_score + 0.01
          interest_categories_hash[category]["latest_update_time"] = Time.now
        else
          updated_source_ids = underlying_source_ids << source.id
          interest_categories_hash[category]["weight"] = previous_score + added_value
          interest_categories_hash[category][tracker_key] = updated_source_ids
          interest_categories_hash[category]["latest_update_time"] = Time.now
        end
      else
        interest_categories_hash[category] = {"weight" => 1.0, tracker_key => [source.id], "latest_update_time" => Time.now}
      end
    end
    interests_hash["venue_categories"] = interest_categories_hash
    
    self.update_columns(interests: interests_hash)
  end

  def update_user_descriptives(venue, favorite_venue=nil, list=nil)
    if venue != nil
      tracker_key = "searched_venue_ids"
      added_value_multiplier = 1.0
      source = venue
    elsif favorite_venue != nil
      tracker_key = "favorite_venue_ids"
      added_value_multiplier = 1.5
      source = favorite_venue
    else
      tracker_key = "joined_list_ids"
      added_value_multiplier = 1.2
      source = list
    end

    interests_hash = self.interests
    descriptives_categories_hash = self.interests["descriptives"] || {}

    if list != nil
      source_top_descriptives = Hash[source.venue_attributes["descriptives"].to_a[0..4]]
    else
      source_top_descriptives = Hash[source.descriptives.to_a[0..4]]
    end

    source_top_descriptives.each do |descriptive, details|
      descriptive = descriptive.downcase
      if descriptives_categories_hash != nil and descriptives_categories_hash[descriptive] != nil
        underlying_source_ids = descriptives_categories_hash[descriptive][tracker_key].to_a
        previous_score = descriptives_categories_hash[descriptive]["weight"].to_f
        if underlying_source_ids != [] and underlying_source_ids.include?(source.id) == true
          descriptives_categories_hash[descriptive]["weight"] = (previous_score.to_f*(underlying_source_ids.count - 1.0) + details["weight"].to_f) / (underlying_source_ids.count) #weighted average
          descriptives_categories_hash[descriptive]["latest_update_time"] = Time.now
        else
          update_source_ids = underlying_source_ids << source.id
          descriptives_categories_hash[descriptive]["weight"] = (previous_score*underlying_source_ids.count + details["weight"].to_f) / (underlying_source_ids.count + 1)
          descriptives_categories_hash[descriptive][tracker_key] = update_source_ids
          descriptives_categories_hash[descriptive]["latest_update_time"] = Time.now
        end
      else
        descriptives_categories_hash[descriptive] = {"weight" => details["weight"].to_f, tracker_key => [source.id], "latest_update_time" => Time.now}
      end
    end
    interests_hash["descriptives"] = descriptives_categories_hash
    
    self.update_columns(interests: interests_hash)
  end

  def add_interest(interest)
    interest = interest.downcase.gsub(" ", "").singularize
    interests_hash = self.interests
    descriptives_keys = interests_hash["descriptives"].keys

    already_present = false
    for key in descriptives_keys
      if JAROW.getDistance(interest, key) >= 0.85
        if interest != key
          interests_hash["descriptives"][interest] = interests_hash["descriptives"][key]                
          interests_hash["descriptives"].delete(key)
        end
        old_weight = interests_hash["descriptives"][interest]["weight"]
        interests_hash["descriptives"][interest]["weight"] = old_weight + 20.0
        already_present = true
        break
      end
    end

    if already_present == false
      interests_hash["descriptives"][interest] = {"weight" => 20.0}
    end

    self.update_columns(interests: interests_hash)
  end

  def remove_interest(interest)
    interests_hash = self.interests
    if interests_hash["descriptives"][interest] != nil 
      interests_hash["descriptives"].delete(interest)
    else
      interests_hash["venue_categories"].delete(interest)
    end
    self.update_columns(interests: interests_hash)
  end

  def increment_interest_by_origin(source, meta_is_category, meta)
    #source type = Searched Venue, Favorite Venue, List
    #meta origin = categories, foursquare_tags, trending_tags
    interests_hash = self.interests
    interests_arr = self.interests.keys

    if source.class.name == "Venue"
      id_tracker = "venue_ids"
      weights = {:new => 2, :repeat => 1}
    elsif source.class.name == "FavoriteVenue"
      id_tracker = "favorite_venue_ids"
      weights = {:new => 1, :repeat => 0.5}
    else
    #List.
      id_tracker = "list_ids"
      weights = {:new => 0.6, :repeat => 0.3}
    end

    if meta_is_category == true
      multiplier = 2.0
    else
      multiplier = 1.0
    end

    if meta.count > 0
      for entry in meta
        if interests_arr.count > 0
          for interest in interests_arr
            jarow_winkler_proximity = JAROW.getDistance(interest, entry)
            if jarow_winkler_proximity > 0.9
              #interest already present need to increment score.
              old_score = interests_hash[interest]["score"]
              venue_ids_arr = interests_hash[interest][id_tracker]

              if venue_ids_arr.include? source.id
                #venue has been previously searched for.
                new_score = old_score + weights[:repeat]*multiplier
                interests_hash[interest]["score"] = new_score
              else
                #venue has just been search for the first time.
                new_score = old_score + weights[:new]*multiplier
                interests_hash[interest]["score"] = new_score
                new_venue_ids_arr = venue_ids_arr + [source.id]
                interests_hash[interest][id_tracker] = new_venue_ids_arr
              end
            else
              #new interest, need to add it to the user's interests.
              interests_hash[entry.downcase] = {"score" => weights[:new]*multiplier, "venue_ids" => [source.id]}
            end
          end
        else
          interests_hash[entry.downcase] = {"score" => weights[:new]*multiplier, "venue_ids" => [source.id]}
        end
      end
    end 
    self.update_columns(interests: interests_hash)
  end

  def notify_friends_of_joining(fb_friend_ids, fb_name, fb_id)
    if fb_friend_ids != ""
      friends = User.where("facebook_id IN (#{fb_friend_ids})")
      for friend in friends
        send_friend_joined_lytit_notification(friend, self, fb_name, fb_id)
      end
    end
  end

  def send_friend_joined_lytit_notification(existing_user, new_user, new_user_fb_name, new_user_fb_id)
    payload = {
      :intended_for => existing_user.id,
      :object_id => new_user.id,
      :user_id => new_user.id,
      :type => "facebook_friend_notification",
      :user_name => new_user.name,
      :fb_id => new_user_fb_id,
      :fb_name => new_user_fb_name
    }

    type = "#{existing_user.id}/friend_joined/#{new_user.id}"

    notification = self.store_new_friend_joined_lytit_notification(payload, existing_user, type)
    payload[:notification_id] = notification.id

    preview = "#{new_user_fb_name} has joined Lytit! Check out their Lists!"
    
    if existing_user.push_token && existing_user.active == true
      count = Notification.where(user_id: existing_user.id, read: false, deleted: false).count
      APNS.send_notification(existing_user.push_token, { :priority =>10, :alert => preview, :content_available => 1, :other => payload, :badge => count})
    end
    
  end

  def store_new_friend_joined_lytit_notification(payload, existing_user, type)
    notification = {
      :payload => payload,
      :gcm => existing_user.gcm_token.present?,
      :apns => existing_user.push_token.present?,
      :response => nil,
      :user_id => existing_user.id,
      :read => false,
      :message => type,
      :deleted => false
    }
    Notification.create(notification)
  end

  def lytit_facebook_friends(fb_friend_ids)
    friends = User.where("facebook_id IN (#{fb_friend_ids})").includes(:feed_invitations).order("facebook_name ASC")
  end

  def User.purge_cached_news_feed(u_ids)
    for u_id in u_ids
      cache_key = "user/#{u_id}/featured_venues"
      Rails.cache.delete(cache_key)
      page = 1
      while Rails.cache.delete("user/#{u_id}/list_feed/page_"+page.to_s) == true do
        page += 1
      end    
    end
  end

=begin
  def surrounding_venues(lat, long)
    center_point = [lat, long]
    proximity_box = Geokit::Bounds.from_point_and_radius(center_point, 0.15, :units => :kms)
    surrounding_lit_venues = Venue.in_bounds(proximity_box).where("color_rating > -1.0")

    if surrounding_lit_venues.first != nil
      results = surrounding_lit_venues.order("(ACOS(least(1,COS(RADIANS(#{lat}))*COS(RADIANS(#{long}))*COS(RADIANS(venues.latitude))*COS(RADIANS(venues.longitude))+COS(RADIANS(#{lat}))*SIN(RADIANS(#{long}))*COS(RADIANS(venues.latitude))*SIN(RADIANS(venues.longitude))+SIN(RADIANS(#{lat}))*SIN(RADIANS(venues.latitude))))*6376.77271) ASC")
    else    
      meter_radius = 100
      surrounding_instagrams = (Instagram.media_search(lat, long, :distance => meter_radius, :count => 20, :min_timestamp => (Time.now-24.hours).to_time.to_i)).sort_by{|inst| Venue.spherecial_distance_between_points(lat, long, inst.location.latitude, inst.location.longitude)}
      surrounding_instagrams.map!(&:to_hash)
      VenueComment.delay.convert_bulk_instagrams_to_vcs(surrounding_instagrams, nil)
      results = surrounding_instagrams.uniq! {|instagram| instagram["location"]["name"] }
    end

    return results
  end
=end

  def top_favorite_venues
    FavoriteVenue.where("user_id = ? AND interest_score * (SELECT popularity_rank FROM venues WHERE id = favorite_venues.venue_id) > 0", self.id).order("
      interest_score * (SELECT popularity_rank FROM venues WHERE id = favorite_venues.venue_id) DESC").limit(5)
  end

  #IV. Lists
  def aggregate_list_feed
    user_feed_ids = "SELECT feed_id FROM feed_users WHERE user_id = #{self.id}"
    user_feed_venue_ids = "SELECT venue_id FROM feed_venues WHERE feed_id IN (#{user_feed_ids})"
    featured_venue_ids = "SELECT id FROM venues WHERE id IN (#{user_feed_venue_ids}) ORDER BY popularity_rank DESC LIMIT 10"
    featured_activity_ids = "SELECT id FROM activities WHERE venue_id IN (#{featured_venue_ids}) AND (activity_type = 'featured_venue_post' OR activity_type = 'featured_venue_tweet')"
    feed = Activity.where("id IN (#{featured_activity_ids}) OR (feed_id IN (#{user_feed_ids}) AND id NOT IN (#{featured_activity_ids}))")
  end

=begin
  def aggregate_list_feed(max_id)
    user_feed_ids = "SELECT feed_id FROM feed_users WHERE user_id = #{self.id}"
    if max_id != nil && max_id != 0
      activity_ids = "SELECT activity_id FROM activity_feeds WHERE feed_id IN (#{user_feed_ids}) AND activity_id < #{max_id}"
    else
      activity_ids = "SELECT activity_id FROM activity_feeds WHERE feed_id IN (#{user_feed_ids})"
    end
    Activity.where("id IN (#{activity_ids}) AND adjusted_sort_position IS NOT NULL AND created_at >= ?", Time.now-1.day).includes(:venue).order("adjusted_sort_position DESC")
  end
=end 

  def live_list_venues
    user_feed_ids = "SELECT feed_id FROM feed_users WHERE user_id = #{self.id}"
    user_venue_ids = "SELECT venue_id FROM feed_venues WHERE feed_id IN (#{user_feed_ids})"
    Venue.where("id IN (#{user_venue_ids}) AND is_live IS TRUE").order("name ASC")
  end

  #determine which venues the user should be updated about as determined by the list they are in and the amount of activity they are experiencing
  def featured_list_venues
    interest_weight = 0.6
    rating = rating_weight = (1 - interest_weight)
    feed_ids = "SELECT feed_id FROM feed_users WHERE user_id = #{self.id}" 
    venue_ids = "SELECT venue_id FROM feed_venues WHERE feed_id IN (#{feed_ids})"

    #sql = "SELECT id, (#{rating_weight}*rating+#{interest_weight}*(SELECT interest_score FROM feed_users WHERE feed_id IN (#{feed_ids}) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) AS relevance_score FROM venues WHERE id IN (#{venue_ids}) AND rating IS NOT NULL GROUP BY id ORDER BY relevance_score DESC LIMIT 5"
    #sql = "SELECT id, (#{rating_weight}*rating+#{interest_weight}*(SELECT interest_score FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = id) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) AS relevance_score FROM venues WHERE id IN (#{venue_ids}) AND (rating IS NOT NULL) GROUP BY id ORDER BY relevance_score DESC LIMIT 5"
    #sql = "SELECT name, id, (#{rating_weight}*rating+#{interest_weight}*(SELECT interest_score FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{l.id} ORDER BY interest_score DESC LIMIT 1)) AS relevance_score FROM venues WHERE (id IN (#{venue_ids}) AND rating IS NOT NULL) GROUP BY id ORDER BY relevance_score DESC LIMIT 5"
    #sql = "SELECT name, id, (SELECT feed_id FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{l.id} ORDER BY interest_score DESC LIMIT 1) AS underlying_list_id, (#{rating_weight}*rating+#{interest_weight}*(SELECT interest_score FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{l.id} ORDER BY interest_score DESC LIMIT 1)) AS relevance_score FROM venues WHERE (id IN (#{venue_ids}) AND rating IS NOT NULL) GROUP BY id ORDER BY relevance_score DESC LIMIT 5"
    
    #l = sql = "SELECT name, id, (SELECT name FROM feeds WHERE id = (SELECT feed_id FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) as list_name, (SELECT id FROM feeds WHERE id = (SELECT feed_id FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) as list_id, (#{rating_weight}*rating+#{interest_weight}*(SELECT interest_score FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) AS relevance_score FROM venues WHERE (id IN (#{venue_ids}) AND rating IS NOT NULL) GROUP BY id ORDER BY relevance_score DESC LIMIT 5"
=begin
    first_4_featured_results = "SELECT 
      id,
      name, 
      latitude,
      longitude,
      address,
      city,
      state,
      country,
      color_rating,
      instagram_location_id, 
      (SELECT meta FROM meta_data WHERE venue_id = venues.id ORDER BY relevance_score DESC LIMIT 1) AS tag_1,
      (SELECT meta FROM meta_data WHERE venue_id = venues.id ORDER BY relevance_score DESC LIMIT 1 OFFSET 1) AS tag_2,
      (SELECT meta FROM meta_data WHERE venue_id = venues.id ORDER BY relevance_score DESC LIMIT 1 OFFSET 2) AS tag_3,
      (SELECT meta FROM meta_data WHERE venue_id = venues.id ORDER BY relevance_score DESC LIMIT 1 OFFSET 3) AS tag_4,
      (SELECT meta FROM meta_data WHERE venue_id = venues.id ORDER BY relevance_score DESC LIMIT 1 OFFSET 4) AS tag_5,
      (SELECT id FROM venue_comments WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS venue_comment_id,
      (SELECT time_wrapper FROM venue_comments WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS venue_comment_created_at,
      (SELECT media_type FROM venue_comments WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS media_type,
      (SELECT thirdparty_username FROM venue_comments WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS venue_comment_thirdparty_username,
      (SELECT content_origin FROM venue_comments WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS venue_comment_content_origin,
      (SELECT image_url_1 FROM venue_comments WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS image_url_1,
      (SELECT image_url_2 FROM venue_comments WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS image_url_2,
      (SELECT image_url_3 FROM venue_comments WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS image_url_3,
      (SELECT video_url_1 FROM venue_comments WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS video_url_1,
      (SELECT video_url_2 FROM venue_comments WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS video_url_2,
      (SELECT video_url_3 FROM venue_comments WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS video_url_3,
      (SELECT name FROM feeds WHERE id = (SELECT feed_id FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) AS feed_name, 
      (SELECT id FROM feeds WHERE id = (SELECT feed_id FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) AS feed_id,
      (SELECT feed_color FROM feeds WHERE id = (SELECT feed_id FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) AS feed_color, 
      (#{rating_weight}*rating+#{interest_weight}*(SELECT interest_score FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) AS relevance_score 
      FROM venues WHERE (id IN (#{venue_ids}) AND rating IS NOT NULL) GROUP BY id ORDER BY relevance_score DESC LIMIT 4"

    last_2_featured_results = "SELECT 
      id,
      name, 
      latitude,
      longitude,
      address,
      city,
      state,
      country,
      color_rating,
      instagram_location_id, 
      (SELECT meta FROM meta_data WHERE venue_id = venues.id ORDER BY relevance_score DESC LIMIT 1) AS tag_1,
      (SELECT meta FROM meta_data WHERE venue_id = venues.id ORDER BY relevance_score DESC LIMIT 1 OFFSET 1) AS tag_2,
      (SELECT meta FROM meta_data WHERE venue_id = venues.id ORDER BY relevance_score DESC LIMIT 1 OFFSET 2) AS tag_3,
      (SELECT meta FROM meta_data WHERE venue_id = venues.id ORDER BY relevance_score DESC LIMIT 1 OFFSET 3) AS tag_4,
      (SELECT meta FROM meta_data WHERE venue_id = venues.id ORDER BY relevance_score DESC LIMIT 1 OFFSET 4) AS tag_5,
      (SELECT id FROM tweets WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS tweet_id,
      (SELECT twitter_id FROM tweets WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS twitter_id,
      (SELECT tweet_text FROM tweets WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS tweet_text,
      (SELECT author_id FROM tweets WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS tweet_author_id,
      (SELECT author_name FROM tweets WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS tweet_author_name,
      (SELECT author_avatar FROM tweets WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS tweet_author_avatar,
      (SELECT timestamp FROM tweets WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS tweet_created_at,
      (SELECT handle FROM tweets WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS tweet_handle,
      (SELECT image_url_1 FROM tweets WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS image_url_1,
      (SELECT image_url_2 FROM tweets WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS image_url_2,
      (SELECT image_url_3 FROM tweets WHERE venue_id = venues.id ORDER BY id DESC LIMIT 1) AS image_url_3,
      (SELECT name FROM feeds WHERE id = (SELECT feed_id FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) AS feed_name, 
      (SELECT id FROM feeds WHERE id = (SELECT feed_id FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) AS feed_id,
      (SELECT feed_color FROM feeds WHERE id = (SELECT feed_id FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) AS feed_color, 
      (#{rating_weight}*rating+#{interest_weight}*(SELECT interest_score FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) AS relevance_score 
      FROM venues WHERE (id IN (#{venue_ids}) AND rating IS NOT NULL) GROUP BY id ORDER BY relevance_score DESC LIMIT 2 OFFSET 4"
=end

    first_10_featured_results = "SELECT 
      id,
      name, 
      latitude,
      longitude,
      address,
      city,
      state,
      country,
      color_rating,
      instagram_location_id,
      tag_1,
      tag_2,
      tag_3,
      tag_4,
      tag_5,
      venue_comment_id,
      venue_comment_created_at,
      venue_comment_content_origin,
      venue_comment_thirdparty_username,
      media_type,
      image_url_1,
      image_url_2,
      image_url_3,
      video_url_1,
      video_url_2,
      video_url_3,
      lytit_tweet_id,
      twitter_id,
      tweet_text,
      tweet_created_at,
      tweet_author_name,
      tweet_author_id,
      tweet_author_avatar_url,
      tweet_handle,
      venue_comment_instagram_id,
      venue_comment_instagram_user_id,

      (#{rating_weight}*rating+#{interest_weight}*(SELECT interest_score FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) AS relevance_score 
      FROM venues WHERE (id IN (#{venue_ids}) AND rating IS NOT NULL AND (NOW() - latest_posted_comment_time) <= INTERVAL '1 HOUR') GROUP BY id ORDER BY relevance_score DESC LIMIT 10"

    results = ActiveRecord::Base.connection.execute(first_10_featured_results).to_a
    #results = ActiveRecord::Base.connection.execute(first_4_featured_results).to_a + ActiveRecord::Base.connection.execute(last_2_featured_results).to_a
    #Activity.delay.create_featured_list_venue_activities(results, nil, nil, nil)
    return results.shuffle
  end


  #------------------------------------------------------------->

  #V. Administrative/Creation Methods------------------------------>
  def self.authenticate_by_username(username, password)
    return nil  unless look_up_user = User.find_by_name(username)
    return look_up_user if     look_up_user.authenticated?(password)
  end

  def send_email_validation
    Mailer.delay.email_validation(self)
  end

  # This is to deal with S3.
  def email_with_id
    "#{email}-#{id}"
  end

  def set_version(v)
    update_columns(version: v)
  end

  def validate_email
    self.email_confirmed = true
    self.confirmation_token = nil
    self.save
  end

  def is_venue_manager?
    role.try(:name) == "Venue Manager"
  end

  def is_admin?
    role.try(:name) == "Admin"
  end

  def version_compatible?(ver)
    version_split = self.version.split(".")
    v0 = version_split[0].to_i
    u0 = version_split[1].to_i || 0
    p0 = version_split[2].to_i || 0 

    target_version = ver.split(".")
    v1 = target_version[0].to_i
    u1 = target_version[1].to_i || 0
    p1 = target_version[2].to_i || 0

    if v0 > v1 
      return true
    elsif v0 >= v1 && u0 > u1
      return true
    elsif (v0 >= v1 && u0 >= u1) && (p0 >= p1)
      return true
    else
      return false
    end

  end

  def manages_any_venues?
    venues.size > 0
  end

  def self.find_lytit_users_in_phonebook(phonebook)
    matched_users = User.where("RIGHT(phone_number, 7) IN (?)", phonebook).to_a
    for user in matched_users
      phone_num = user.phone_number
      if phone_num.length > 7
        leading_digits = phone_num.first(phone_num.length-7)
        phonebook_entry = phonebook[phonebook.index(phone_num.last(7))-1].last(phone_num.length)
        leading_phonebook_entry_digits = phonebook_entry.first(phone_num.length-7)

        if leading_digits != leading_phonebook_entry_digits
          matched_users.delete(user)
        else
          #compare country codes
          if phone_num.length != phonebook_entry.length
            if user.country_code != phonebook_entry.first(user.country_code.length)
              matched_users.delete(user)
            end
          end
        end
      end
    end

    return matched_users
  end

  def self.generate_support_issues
    users_with_support = "SELECT user_id FROM support_issues"
    not_supported_users = User.where("id NOT IN (#{users_with_support})").pluck(:id)
    not_supported_users.each{|user_id| SupportIssue.create!(user_id: user_id)}
  end

  def update_list_activity_user_details
    self.activities.update_all(user_name: self.name)
    self.activities.update_all(user_phone: self.phone_number) 
  end
  #--------------------------------------------------------------> 

  #-------------------------------------------------------------->

  def self.lumen_cleanup
    VenueComment.where("created_at < ?", Time.now - 24.hours).delete_all
    MetaData.where("created_at < ?", Time.now - 24.hours).delete_all
    Tweet.where("created_at < ?", Time.now - 24.hours).delete_all
    LytSphere.where("created_at < ?", Time.now - 24.hours).delete_all
    LytitVote.where("created_at < ?", Time.now - 24.hours).delete_all
  end

  def User.clear_user_notifications(user_id_s)
    if user_id_s.kind_of?(Array)
      user_id_s.each{|user_id| Notification.where(user_id: user_id, read: false, deleted: false).delete_all}
    else
      Notification.where(user_id: user_id_s, read: false, deleted: false).delete_all
    end
  end


  private 

  def generate_confirmation_token_for_venue_manager
    if role_id_changed?
      if role.try(:name) == "Venue Manager"
        self.confirmation_token = SecureRandom.hex
      end    
    end
  end

  def generate_user_confirmation_token
    if self.confirmation_token.blank?
      self.confirmation_token = SecureRandom.hex
    end
  end

  def notify_venue_managers
    if role_id_changed?
      if role.try(:name) == "Venue Manager"
        Mailer.delay.welcome_venue_manager(self)
      end    
    end
  end

  def ensure_authentication_token
    unless self.authentication_token.present?
      begin
        self.authentication_token = SecureRandom.hex
      end while self.class.exists?(authentication_token: authentication_token)
    end
  end

end