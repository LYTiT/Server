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

  has_many :likes, foreign_key: "liker_id", dependent: :destroy
  has_many :liked_users, through: :likes, source: :liked
  has_many :reverse_likes, foreign_key: "liked_id", class_name: "Like", dependent: :destroy
  has_many :likers, through: :reverse_likes, source: :liker

  has_many :feed_invitations, foreign_key: "inviter_id", dependent: :destroy
  has_many :invitee_users, through: :feed_invitations, source: :invitee
  has_many :sent_feed_invitations, foreign_key: "invitee_id", class_name: "FeedInvitation", dependent: :destroy
  has_many :inviters, through: :sent_feed_invitations, source: :inviter

  has_many :temp_posting_housings, :dependent => :destroy

  has_many :feed_users, :dependent => :destroy
  has_many :feeds, through: :feed_users
  has_many :instagram_auth_tokens

  has_many :activities, :dependent => :destroy
  has_many :activity_comments, :dependent => :destroy

  has_many :support_issues, :dependent => :destroy
  has_many :surrounding_pull_trackers, :dependent => :destroy
  has_many :support_messages, :dependent => :destroy

  belongs_to :role

  before_save :ensure_authentication_token
  before_save :generate_confirmation_token_for_venue_manager
  before_save :generate_user_confirmation_token
  after_save :notify_venue_managers


  #I.
  def update_user_feeds
    non_checked_feeds = feeds.where("new_media_present IS FALSE")
    for feed in non_checked_feeds
      for feed_venue in feed.venues
        if feed_venue.get_instagrams(false).first.try(:created_at) == nil && feed.new_media_present == false
          feed.update_columns(latest_content_time: Time.now)
          feed.update_columns(new_media_present: true)
        end
      end
    end
  end 


  #II. Lumen Related Methods------------------------------------------->
  
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
  #------------------------------------------------------------->



  #III. Visual Graph Method------------------------------------------>
  def total_bonuses
    LumenValue.where("user_id = ? AND media_type = ? AND created_at >= ?", self.id, 'bonus', DateTime.new(2015,4,30)).count
  end

  def total_video_comments
    self.venue_comments.where("media_type = ? AND created_at >= ?", 'video', DateTime.new(2015,4,30)).count
  end

  def total_image_comments
    self.venue_comments.where("media_type = ? AND created_at >= ?", 'image', DateTime.new(2015,4,30)).count
  end

  def total_text_comments
    self.venue_comments.where("media_type = ? AND created_at >= ?", 'text', DateTime.new(2015,4,30)).count
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

      min_lumen = total_lumens.min

      range = (span - 65)/ (1 + (min_lumen / self.lumens))
      radius = span - range

      radii["video"] = ((video_lumens / self.lumens) * range + radius) >= (range + radius) ? (range + radius) : ((video_lumens / self.lumens) * range + radius)
      radii["image"] = ((image_lumens / self.lumens) * range + radius) >= (range + radius) ? (range + radius) : ((image_lumens / self.lumens) * range + radius)
      radii["text"] = ((text_lumens / self.lumens) * range + radius) >= (range + radius) ? (range + radius) : ((text_lumens / self.lumens) * range + radius)
      radii["bonus"] = ((bonus_lumens / self.lumens) * range + radius) >= (range + radius) ? (range + radius) : ((bonus_lumens / self.lumens) * range + radius)

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

  def views_radius
    if total_views == 0
      0
    else
      [Math::log(total_views) + 70, 85].min
    end
  end

  def mapped_places_count
    VenueComment.where("user_id = ?", self.id).uniq.pluck(:venue_id).count
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
  #------------------------------------------------------------->

  #IV. Lists

  def aggregate_list_feed
    user_feed_ids = "SELECT feed_id FROM feed_users WHERE user_id = #{self.id}"
    activity_ids = "SELECT activity_id FROM activity_feeds WHERE feed_id IN (#{user_feed_ids})"
    Activity.where("id IN (#{activity_ids}) AND (NOW() - created_at) <= INTERVAL '1 DAY' AND adjusted_sort_position IS NOT NULL").includes(:feed, :user, :venue, :venue_comment, :likes).order("adjusted_sort_position DESC")
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
  #-------------------------------------------------------------->

  def self.lumen_cleanup
    VenueComment.where("created_at < ?", Time.now - 24.hours).delete_all
    MetaData.where("created_at < ?", Time.now - 24.hours).delete_all
    Tweet.where("created_at < ?", Time.now - 24.hours).delete_all
    LytSphere.where("created_at < ?", Time.now - 24.hours).delete_all
    LytitVote.where("created_at < ?", Time.now - 24.hours).delete_all
  end

  def User.clear_user_notifications(user_ids)
    user_ids.each{|user_id| Notification.where(user_id: user_id, read: false, deleted: false).delete_all}
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
