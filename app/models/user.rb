class User < ActiveRecord::Base
  include Clearance::User

  attr_accessor :password_confirmation

  validates_uniqueness_of :name, :case_sensitive => false
  validates :name, presence: true, format: { with: /\A(^@?(\w){1,40}$)\Z/i}
  validates :venues, presence: true, if: Proc.new {|user| user.role.try(:name) == "Venue Manager"}
  validates :venues, absence: true, if: Proc.new {|user| user.role.try(:name) != "Venue Manager"}
  validates :email, presence: true, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
  validates_length_of :password, :minimum => 8, unless: :skip_password_validation?

  has_many :venue_ratings, :dependent => :destroy
  has_many :venue_comments, :dependent => :destroy
  has_many :flagged_comments, :dependent => :destroy
  has_many :venues

  has_many :lumen_values, :dependent => :destroy

  has_many :announcement_users, :dependent => :destroy
  has_many :announcements, through: :announcement_users

  has_many :temp_posting_housings, :dependent => :destroy

  has_many :bounties, :dependent => :destroy
  has_many :bounty_subscribers, :dependent => :destroy

  belongs_to :role

  before_save :ensure_authentication_token
  before_save :generate_confirmation_token_for_venue_manager
  before_save :generate_user_confirmation_token
  after_save :notify_venue_managers

  
  def surprise_image_url
    image_url = nil
    if image_url == nil
      return nil
    else
      return image_url
    end
  end

  #clear all outstanding user lumens
  def self.global_lumen_recalibration
    LumenValue.delete_all
    all = User.all
    for person in all
      person.lumens = 5.0
      person.video_lumens = 0.0
      person.image_lumens = 0.0
      person.text_lumens = 0.0
      person.bonus_lumens = 5.0
      person.lumen_percentile = 0.0
      person.total_views = 0
      person.lumen_notification = 0.0
      person.save
      l = LumenValue.new(:value => 5.0, :user_id => person.id, :media_type => "bonus")
      l.save
    end
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

   #Global activity feed (venue comments, bounties, bounty responses)
  def global_feed
    days_back = 1
    responded_to_bounty_ids = "SELECT id FROM bounties WHERE (expiration >= NOW() OR (expiration < NOW() AND num_responses > 0)) AND (NOW() - created_at) <= INTERVAL '1 DAY'"
    if self.version == "1.0.0"
      feed = VenueComment.where("(created_at >= ? AND (bounty_id NOT IN (#{responded_to_bounty_ids}) OR bounty_id IS NULL) AND user_id IS NOT NULL) OR (bounty_id IN (#{responded_to_bounty_ids})) OR (content_origin = ?)", (Time.now - days_back.days), 'instagram').includes(:venue, :bounty, bounty: :bounty_subscribers).order("time_wrapper desc")
    else
      feed = VenueComment.where("(created_at >= ? AND bounty_id IS NULL AND user_id IS NOT NULL) OR (bounty_id IN (#{responded_to_bounty_ids}) AND user_id IS NULL) OR (content_origin = ?)", (Time.now - days_back.days), 'instagram').includes(:venue, :bounty, bounty: :bounty_subscribers).order("time_wrapper desc")
    end
  end 

  def total_user_bounties
    subcribed_bounty_ids = "SELECT bounty_id FROM bounty_subscribers WHERE user_id = #{self.id}"
    total_bounties = Bounty.where("(id IN (#{subcribed_bounty_ids}) AND user_id != ? AND (NOW() <= expiration OR ((NOW() - created_at) <= INTERVAL '1 DAY' AND num_responses > 0))) OR (user_id = ? AND validity = TRUE AND (NOW() - created_at) <= INTERVAL '1 DAY')", self.id, self.id).includes(:venue).order('id DESC')
  end

  def nearby_user_bounties(lat, long, city, state, country)
    meter_radius = 400
    mile_radius = meter_radius * 0.000621371
    
    #returns nearby venue bounties sorted by proximity
    venue_bounties = VenueComment.joins(:venue).where("(ACOS(least(1,COS(RADIANS(#{lat}))*COS(RADIANS(#{long}))*COS(RADIANS(venues.latitude))*COS(RADIANS(venues.longitude))+COS(RADIANS(#{lat}))*SIN(RADIANS(#{long}))*COS(RADIANS(venues.latitude))*SIN(RADIANS(venues.longitude))+SIN(RADIANS(#{lat}))*SIN(RADIANS(venues.latitude))))*3963.1899999999996) 
      <= #{mile_radius} AND (outstanding_bounties = 0)").order("(ACOS(least(1,COS(RADIANS(#{lat}))*COS(RADIANS(#{long}))*COS(RADIANS(venues.latitude))*COS(RADIANS(venues.longitude))+COS(RADIANS(#{lat}))*SIN(RADIANS(#{long}))*COS(RADIANS(venues.latitude))*SIN(RADIANS(venues.longitude))+SIN(RADIANS(#{lat}))*SIN(RADIANS(venues.latitude))))*3963.1899999999996) ASC").where("venue_comments.created_at >= ? 
      AND venue_comments.bounty_id IS NOT NULL AND venue_comments.user_id IS NULL", Time.now-1.day)

    #total surrounding bounties including surrounding geo (city, state, or country) bounties  
    total_surrounding_bounties = VenueComment.joins(:venue).where("address IS NULL AND postal_code is NULL AND ((city = ? AND name = ?) OR (state = ? AND city IS NULL) OR (country = ? AND city IS NULL AND state IS NULL))", city, city, state, country).where("venue_comments.created_at >= ? 
      AND venue_comments.bounty_id IS NOT NULL AND venue_comments.user_id IS NULL", Time.now-1.day) << venue_bounties
  end

  def is_subscribed_to_bounty?(target_bounty)
    if target_bounty != nil
      BountySubscriber.where("bounty_id = ? and user_id = ?", target_bounty.id, self.id).count > 0 ? true : false
    else
      nil
    end
  end

  def did_respond?(target_bounty)
    if target_bounty != nil
      VenueComment.where("user_id = #{self.id} AND is_response = TRUE AND bounty_id = #{target_bounty.id}").first ? true : false
    else
      nil
    end
  end

  def update_lumens_after_text(text_id)
    new_lumens = LumenConstants.text_media_weight
    updated_lumens = self.lumens + new_lumens
    gross_lumen_update = self.monthly_gross_lumens + new_lumens

    t_l = self.text_lumens
    update_columns(text_lumens: (t_l + new_lumens).round(4))

    update_columns(lumens: updated_lumens.round(4))
    update_columns(monthly_gross_lumens: gross_lumen_update.round(4))
    #update_lumen_percentile

    l = LumenValue.new(:value => new_lumens.round(4), :user_id => self.id, :venue_comment_id => text_id, :media_type => "text")
    l.save
  end

  #every media post gets at least the text value of Lumens and receives more Lumens when it gets viewed
  def update_lumens_after_media(comment)
    new_lumens = LumenConstants.text_media_weight
    updated_lumens = self.lumens + new_lumens
    gross_lumen_update = self.monthly_gross_lumens + new_lumens

    update_columns(lumens: updated_lumens.round(4))
    update_columns(monthly_gross_lumens: gross_lumen_update.round(4))

    if comment.media_type == "image"
      i_l = self.image_lumens
      update_columns(image_lumens: (i_l + new_lumens).round(4))

      l = LumenValue.new(:value => new_lumens.round(4), :user_id => self.id, :venue_comment_id => comment.id, :media_type => "image")
      l.save
    else
      v_l = self.video_lumens
      update_columns(video_lumens: (v_l + new_lumens).round(4))

      l = LumenValue.new(:value => new_lumens.round(4), :user_id => self.id, :venue_comment_id => comment.id, :media_type => "video")
      l.save
    end
  end

  def update_lumens_after_view(comment)
    if self.adjusted_view_discount == nil || self.adjusted_view_discount > LumenConstants.views_weight_adj
      self.adjusted_view_discount = LumenConstants.views_weight_adj
      save
    end

    time = Time.now
    comment_time = comment.created_at
    time_delta = ((time - comment_time) / 1.minute) / (LumenConstants.views_halflife)
    adjusted_view = 2.0 ** (-time_delta)
    
    previous_lumens = self.lumens
    new_lumens = comment.consider*(comment.weight*adjusted_view*adjusted_view_discount).round(4)
    updated_lumens = previous_lumens + new_lumens
    gross_lumen_update = self.monthly_gross_lumens + new_lumens

    if comment.media_type == 'video'
      v_l = self.video_lumens
      update_columns(video_lumens: (v_l + new_lumens).round(4))
    else
      i_l = self.image_lumens
      update_columns(image_lumens: (i_l + new_lumens).round(4))
    end

    update_columns(lumens: updated_lumens.round(4))
    update_columns(monthly_gross_lumens: gross_lumen_update.round(4))
    #update_lumen_percentile

    if new_lumens > 0
      l = LumenValue.new(:value => new_lumens.round(4), :user_id => self.id, :venue_comment_id => comment.id, :media_type => comment.media_type)
      l.save
    end
  end

  def account_new_bonus_lumens(bonus)
      b_l = self.bonus_lumens + bonus 
      updated_lumens = self.lumens + bonus
      update_columns(bonus_lumens: (b_l).round(4))
      update_columns(lumens: updated_lumens.round(4))
      l = LumenValue.new(:value => bonus.to_f, :user_id => self.id, :media_type => "bonus")
      l.save
  end

  def adjust_lumens
    adjusted_total_lumens = (self.lumens - LumenConstants.text_media_weight).round(4)
    adjusted_text_lumens = (self.text_lumens - LumenConstants.text_media_weight).round(4)

    update_columns(lumens: adjusted_total_lumens)
    update_columns(text_lumens: adjusted_text_lumens)
  end

#====================================================================================================================================================================>
  #Extract acquired Lumens for user on a particulare date
  def lumens_on_date(date)
   lumens_of_date = LumenValue.where("user_id = ? AND created_at <= ? AND created_at >= ?", self.id, date.at_end_of_day, date.at_beginning_of_day).sum(:value)
  end

  def weekly_lumens
    t_1 = (Time.now - 6.days)
    t_2 = t_1 + 1.days
    t_3 = t_2 + 1.days
    t_4 = t_3 + 1.days
    t_5 = t_4 + 1.days
    t_6 = t_5 + 1.days
    t_7 = t_6 + 1.days

    weekly_lumens = [lumens_on_date(t_1).round(4), lumens_on_date(t_2).round(4), lumens_on_date(t_3).round(4), lumens_on_date(t_4).round(4), lumens_on_date(t_5).round(4), lumens_on_date(t_6).round(4), lumens_on_date(t_7).round(4)]
  end

  #Constructs array of color values which determine which color to assign to particular weekly Lumen value on the front-end.
  def weekly_lumen_color_values(weekly_lumens_entries)
    color_values = [] 
    weekly_lumens_entries.each {|l| color_values << color_value_assignment(l)}
    color_values
  end

  #Determining color values for daily lumens. 0 is no Lumens which corresponds to an empty circle, 7 is white.
  def color_value_assignment(value)
    rvalue = value.ceil
    if rvalue == 0
      0
    elsif rvalue.between?(0.00001, 2.0)
      1
    elsif rvalue.between?(2.00001, 3.0)
      2
    elsif rvalue.between?(3.00001, 4.0)
      3
    elsif rvalue.between?(4.00001, 5.0)
      4
    elsif rvalue.between?(5.00001, 6.0)
      5
    elsif rvalue.between?(6.00001, 7.0)
      6
    else 
      7
    end
  end

  #2-D array containing the Lumen value of a day and the corresponding color value
  def lumen_package
    package = weekly_lumens.zip(weekly_lumen_color_values(weekly_lumens))
  end
#===================================================================================================================================================================> 

  def lumen_percentile_calculation
    all_lumens = User.all.map { |user| user.lumens}
    percentile = all_lumens.percentile_rank(self.lumens)
  end

  
  def update_lumen_percentile
    if self.lumens == 0
      update_columns(lumen_percentile: 0)
    else
      all_lumens = User.all.map { |user| user.lumens}
      percentile = all_lumens.percentile_rank(self.lumens)
      update_columns(lumen_percentile: percentile)
    end
  end

  def lumen_rank #we update the percentile everytime we check rank
    total_number = User.count
    rank = User.where("lumens > #{self.lumens}").count+1
    self.lumen_percentile = 100.0*(total_number.to_f-rank.to_f)/total_number.to_f
    self.save
  end

  def total_bonuses
    LumenValue.where("user_id = ? AND media_type = ? AND created_at >= ?", self.id, 'bonus', DateTime.new(2015,4,30)).count
  end

  def total_bounties
    LumenValue.where("user_id = #{self.id} AND bounty_id IS NOT NULL").count
  end

  def total_video_comments
    self.venue_comments.where("media_type = ? AND created_at >= ?", 'video', DateTime.new(2015,4,30)).count
  end

  def total_image_comments
    self.venue_comments.where("media_type = ? AND created_at >= ?", 'image', DateTime.new(2015,4,30)).count
  end

  def total_text_comments
    self.venue_comments.where("media_type = ? AND created_at >= ?", 'image', DateTime.new(2015,4,30)).count
  end


  def update_total_views
    current = total_views
    update_columns(total_views: (current + 1) )
  end

  #averager number of adjusted views received
  def avg_adj_views
    comments = self.venue_comments
    total_adjusted_views = 0
    total_considered_comments = 0

    comments.each do |comment|
      if comment.consider == 1
        total_adjusted_views += comment.adj_views
        total_considered_comments += 1
      end
    end

    total_adjusted_views -= total_text_comments*LumenConstants.text_media_weight
    if total_considered_comments > 0
      average_adj_views = total_adjusted_views / total_considered_comments
    else
      average_adj_views = 0
    end

    average_adj_views
  end


  #Radius assignment to Lumen contributing categories for Lumen breakout screen
  def radius_assignment
    radii = Hash.new

    if self.lumens < 1
      radii["video"] = 0.0
      radii["image"] = 0.0
      radii["text"] = 0.0
      radii["bonus"] = 0.0
      radii["bounty"] = 0.0
      return radii
    else
      perc = lumen_percentile || 91.0

      if perc.between?(0, 10)
        span = 100
      elsif perc.between?(11.0, 20.0)
        span = 105
      elsif perc.between?(21.0, 30.0)
        span = 110
      elsif perc.between?(31.0, 40.0)
        span = 115
      elsif perc.between?(41.0, 50.0)
        span = 120
      elsif perc.between?(51.0, 60.0)
        span = 125
      elsif perc.between?(61.0, 70.0)
        span = 135
      elsif perc.between?(71.0, 80.0)
        span = 140 
      elsif perc.between?(81.0, 90.0)
        span = 145
      else
        span = 150
      end

      total_lumens = []
      total_lumens << video_lumens
      total_lumens << image_lumens
      total_lumens << text_lumens
      total_lumens << bonus_lumens
      total_lumens << bounty_lumens

      min_lumen = total_lumens.min

      range = (span - 65)/ (1 + (min_lumen / self.lumens))
      radius = span - range

      radii["video"] = ((video_lumens / self.lumens) * range + radius) >= (range + radius) ? (range + radius) : ((video_lumens / self.lumens) * range + radius)
      radii["image"] = ((image_lumens / self.lumens) * range + radius) >= (range + radius) ? (range + radius) : ((image_lumens / self.lumens) * range + radius)
      radii["text"] = ((text_lumens / self.lumens) * range + radius) >= (range + radius) ? (range + radius) : ((text_lumens / self.lumens) * range + radius)
      radii["bonus"] = ((bonus_lumens / self.lumens) * range + radius) >= (range + radius) ? (range + radius) : ((bonus_lumens / self.lumens) * range + radius)
      radii["bounty"] = ((bounty_lumens / self.lumens) * range + radius) >= (range + radius) ? (range + radius) : ((bounty_lumens / self.lumens) * range + radius)

      radii2 = Hash[radii.sort_by {|k, v| v}]
      return radii2
    end
  end

  def video_radius
    if video_lumens == 0
      0
    else
      radius_assignment["video"]
    end
  end

  def image_radius
    if image_lumens == 0
      0
    else
      radius_assignment["image"]
    end
  end
  
  def text_radius
    if text_lumens == 0
      0
    else
      radius_assignment["text"]
    end
  end

  def bonus_radius
    if bonus_lumens == 0
      0
    else
      radius_assignment["bonus"]
    end
  end

  def bounty_radius
    if bounty_lumens == 0
      0
    else
      radius_assignment["bounty"]
    end
  end

  def views_radius
    if total_views == 0
      70
    else
      [Math::log(total_views) + 75, 85].min
    end
  end

  #Used for color assignment of Lumen contribution categories in the Lumen breakout screen
  def lumen_video_contribution_rank
    rank = radius_assignment.keys.index("video") + 1
  end

  def lumen_image_contribution_rank
    rank = radius_assignment.keys.index("image") + 1 
  end

  def lumen_text_contribution_rank
    rank = radius_assignment.keys.index("text") + 1
  end

  def lumen_bonus_contribution_rank
    rank = radius_assignment.keys.index("bonus") + 1
  end

  def lumen_bounty_contribution_rank
    rank = radius_assignment.keys.index("bounty") + 1
  end 

  def lumen_views_contribution_rank
    return 5
  end 

  #Average views received per photo/video posting, i.e are Lumens coming from popularity or posting frequency
  def view_density
    if (total_video_comments + total_image_comments) == 0
      return 0
    else
      vd = (total_views*1.0 / (total_video_comments + total_image_comments)).round(4)
      if vd >= 10
        10
      else
        vd.round
      end
    end
  end

  #Sanity check if user is permited to claim Bounties based on his rejection history
  def can_claim_bounties?
    time_out = 1.0 #days
    rejection_rate = 0.5

    if can_claim_bounty == false and (Time.now - latest_rejection_time)/(60*60*24) < time_out
      return false
    else
      total_rejections = BountyClaimRejectionTracker.where("user_id = ? AND active = true AND created_at <= ? AND created_at >= ?", id,  Time.now, (Time.now - 7.days)).count
      total_bounty_claims = VenueComment.where("user_id = #{self.id} AND created_at <= ? AND created_at >= ? AND bounty_id IS NOT NULL", Time.now, (Time.now - 7.days)).count

      if total_bounty_claims >= 20 && (total_rejections.to_f / total_bounty_claims.to_f) > rejection_rate
        self.can_claim_bounty = false
        BountyClaimRejectionTracker.where("user_id = ? AND active = true AND created_at <= ? AND created_at >= ?", Time.now, (Time.now - 7.days)).update_all(active: false)
      else
        self.can_claim_bounty = true
      end

      save
      return self.can_claim_bounty

    end
  end

  def self.instagram_content_pull(lat, long)
    if lat != nil && long != nil
        meter_radius = 20000
        if not Venue.within(Venue.meters_to_miles(meter_radius.to_i), :origin => [lat, long]).where("rating > 0").any?
          new_instagrams = Instagram.media_search(lat, long, :distance => 5000, :count => 100)
          for instagram in new_instagrams
            VenueComment.convert_instagram_to_vc(instagram)
          end
        end
      end
  end    


  private ##################################################################################################

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
