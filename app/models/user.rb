class User < ActiveRecord::Base
  include Clearance::User

  attr_accessor :password_confirmation

  validates_uniqueness_of :name, :case_sensitive => false
  validates :name, presence: true, format: { with: /\A(^@?(\w){1,40}$)\Z/i}
  validates :venues, presence: true, if: Proc.new {|user| user.role.try(:name) == "Venue Manager"}
  validates :venues, absence: true, if: Proc.new {|user| user.role.try(:name) != "Venue Manager"}
  validates :email, presence: true, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
  validates_length_of :password, :minimum => 8, unless: :skip_password_validation?

  #has_many :venue_ratings, :dependent => :destroy
  has_many :venue_comments, :dependent => :destroy
  #has_many :flagged_comments, :dependent => :destroy
  has_many :venues

  has_many :announcement_users, :dependent => :destroy
  has_many :announcements, through: :announcement_users

  has_many :likes, foreign_key: "liker_id", dependent: :destroy
  has_many :liked_users, through: :likes, source: :liked
  has_many :likes_received, foreign_key: "liked_id", class_name: "Like", dependent: :destroy
  has_many :likers, through: :likes_received, source: :liker

  has_many :feed_invitations, foreign_key: "inviter_id", dependent: :destroy
  has_many :invitee_users, through: :feed_invitations, source: :invitee
  has_many :sent_feed_invitations, foreign_key: "invitee_id", class_name: "FeedInvitation", dependent: :destroy
  has_many :inviters, through: :sent_feed_invitations, source: :inviter

  #has_many :temp_posting_housings, :dependent => :destroy

  has_many :feed_users, :dependent => :destroy
  has_many :feeds, through: :feed_users
  has_many :instagram_auth_tokens

  has_many :activities, :dependent => :destroy
  has_many :activity_comments, :dependent => :destroy

  has_one :support_issue, :dependent => :destroy
  #has_many :surrounding_pull_trackers, :dependent => :destroy
  has_many :support_messages, :dependent => :destroy
  has_many :event_organizers, :dependent => :destroy
  has_many :event_announcements, :dependent => :destroy

  has_many :venue_questions

  has_one :live_user

  belongs_to :role

  before_save :ensure_authentication_token
  before_save :generate_confirmation_token_for_venue_manager
  before_save :generate_user_confirmation_token
  after_save :notify_venue_managers


  #I.
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

  def surrounding_venues(lat, long)
    center_point = [lat, long]
    surrounding_lit_venues = Venue.where("color_rating")
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

  #IV. Lists

  def aggregate_list_feed
    user_feed_ids = "SELECT feed_id FROM feed_users WHERE user_id = #{self.id}"
    activity_ids = "SELECT activity_id FROM activity_feeds WHERE feed_id IN (#{user_feed_ids})"
    Activity.where("id IN (#{activity_ids}) AND adjusted_sort_position IS NOT NULL AND created_at >= ?", Time.now-1.day).includes(:feed, :user, :venue, :venue_comment).order("adjusted_sort_position DESC")
  end

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

    sql = "SELECT 
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
      (SELECT meta FROM meta_data WHERE venue_id = venues.id ORDER BY relevance_score DESC LIMIT 1) AS toptag_1,
      (SELECT meta FROM meta_data WHERE venue_id = venues.id ORDER BY relevance_score DESC LIMIT 1 OFFSET 1) AS toptag_2,
      (SELECT meta FROM meta_data WHERE venue_id = venues.id ORDER BY relevance_score DESC LIMIT 1 OFFSET 2) AS toptag_3,
      (SELECT meta FROM meta_data WHERE venue_id = venues.id ORDER BY relevance_score DESC LIMIT 1 OFFSET 3) AS toptag_4,
      (SELECT meta FROM meta_data WHERE venue_id = venues.id ORDER BY relevance_score DESC LIMIT 1 OFFSET 4) AS toptag_5,
      (SELECT name FROM feeds WHERE id = (SELECT feed_id FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) AS list_name, 
      (SELECT id FROM feeds WHERE id = (SELECT feed_id FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) AS list_id,
      (SELECT feed_color FROM feeds WHERE id = (SELECT feed_id FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) AS list_color, 
      (#{rating_weight}*rating+#{interest_weight}*(SELECT interest_score FROM feed_users WHERE feed_id IN (SELECT feed_id FROM feed_venues WHERE venue_id = venues.id) AND user_id = #{self.id} ORDER BY interest_score DESC LIMIT 1)) AS relevance_score 
      FROM venues WHERE (id IN (#{venue_ids}) AND rating IS NOT NULL) GROUP BY id ORDER BY relevance_score DESC LIMIT 5"
    results = ActiveRecord::Base.connection.execute(sql)
    #Activity.delay.create_featured_list_venue_activities(featured_venue_entries)
    return results
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

  def checkout_user_from_venue
    user_live_venue = self.live_user.venue
    self.live_user.delete  
    if LiveUser.where("venue_id = ?", user_live_venue.id).count == 0
      user_live_venue.update_columns(is_live: false)
    end
  end

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