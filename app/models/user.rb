class User < ActiveRecord::Base
  include Clearance::User

  attr_accessor :password_confirmation

  validates_uniqueness_of :name, :case_sensitive => false
  validates :name, presence: true
  validates :venues, presence: true, if: Proc.new {|user| user.role.try(:name) == "Venue Manager"}
  validates :venues, absence: true, if: Proc.new {|user| user.role.try(:name) != "Venue Manager"}
  validates :email, presence: true, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
  validates_length_of :password, :minimum => 8, unless: :skip_password_validation?

  has_many :venue_ratings, :dependent => :destroy
  has_many :venue_comments, :dependent => :destroy
  has_many :groups_users, :dependent => :destroy
  has_many :groups, through: :groups_users
  has_many :flagged_comments, :dependent => :destroy
  has_many :venues
  
  has_many :relationships, foreign_key: "follower_id", dependent: :destroy
  has_many :followed_users, through: :relationships, source: :followed
  has_many :reverse_relationships, foreign_key: "followed_id", class_name: "Relationship", dependent: :destroy
  has_many :followers, through: :reverse_relationships, source: :follower
  
  has_many :venue_relationships, foreign_key: "ufollower_id", dependent: :destroy
  has_many :followed_venues, through: :venue_relationships, source: :vfollowed

  has_many :lumen_values, :dependent => :destroy

  belongs_to :role

  before_save :ensure_authentication_token
  before_save :generate_confirmation_token_for_venue_manager
  after_save :notify_venue_managers
  
  # This is to deal with S3.
  def email_with_id
    "#{email}-#{id}"
  end

  def toggle_group_notification(group_id, enabled)
    group_user = GroupsUser.where("group_id = ? and user_id = ?", group_id, self.id).first
    if group_user
      group_user.update(:notification_flag => (enabled == 'yes' ? true : false))
      return true
    else
      return false, 'You are not member of this group'
    end
  end

  def is_venue_manager?
    role.try(:name) == "Venue Manager"
  end

  def is_admin?
    role.try(:name) == "Admin"
  end

  def manages_any_venues?
    venues.size > 0
  end

  def send_location_added_to_group_notification?(group)
    self.notify_location_added_to_groups and GroupsUser.send_notification?(group.id, self.id)
  end

  def send_event_added_to_group_notification?(group)
    self.notify_events_added_to_groups and GroupsUser.send_notification?(group.id, self.id)
  end

  def following?(other_user)
    relationships.find_by(followed_id: other_user.id) ? true : false
  end
  #follows a user
  def follow!(other_user)
    relationships.create!(followed_id: other_user.id)
  end

  def unfollow!(other_user)
    relationships.find_by(followed_id: other_user.id).destroy
  end

  #follows a venue
  def vfollow!(venue)
    venue_relationships.create!(vfollowed_id: venue.id)
  end

  def vunfollow!(venue)
    venue_relationships.find_by(vfollowed_id: venue.id).destroy
  end

  def vfollowing?(venue)
    venue_relationships.find_by(vfollowed_id: venue.id) ? true : false
  end

  def userfeed
    VenueComment.from_users_followed_by(self)
  end

  def venuefeed
    VenueComment.where("venue_id IN(?)", self.followed_venues.ids)
  end

  def totalfeed
    (userfeed+venuefeed).uniq 
  end

  #Lumens are acquired only after voting or posted content receives a view
  def update_lumens_after_vote
    new_lumens = LumenConstants.votes_weight_adj
    updated_lumens = self.lumens + new_lumens
    update_columns(lumens: updated_lumens)

    l = LumenValues.new(:value => new_lumens, :user_id => self.id)
    l.save
  end

  def update_lumens_after_view(comment)
    time = Time.now
    comment_time = comment.created_at
    time_delta = ((time - comment_time) / 1.minute) / (LumenConstants.views_halflife)
    adjusted_view = 2.0 ** (-time_delta)
    
    previous_lumens = self.lumens
    new_lumens = comment.consider*(comment.weight*adjusted_view*LumenConstants.views_weight_adj)
    updated_lumens = previous_lumens + new_lumens
    update_columns(lumens: updated_lumens.round(4))
    update_lumen_percentile

    if new_lumens > 0
      l = LumenValues.new(:value => new_lumens.round(4), :user_id => self.id)
      l.save
    end
  end

   #Lumen Calculation
  def calculate_lumens()
    comments = self.venue_comments
    lumens = self.total_votes*LumenConstants.votes_weight_adj

    comments.each {|comment| lumens += comment.consider*(comment.weight*comment.adj_views*LumenConstants.views_weight_adj)}
    update_columns(lumens: lumens.round(4))
  end

  #Extract acquired Lumens for user on a particulare date
  def lumens_on_date(date)
   lumens_of_date = LumenValues.where("user_id = ? AND created_at <= ? AND created_at >= ?", self.id, date.at_end_of_day, date.at_beginning_of_day)
   lumens_of_date.inject(0) { |sum, l| sum + l.value}
  end

  def weekly_lumens
    t_1 = Time.now + 4.hours - 6.days
    t_2 = t_1 + 1.days
    t_3 = t_2 + 1.days
    t_4 = t_3 + 1.days
    t_5 = t_4 + 1.days
    t_6 = t_5 + 1.days
    t_7 = t_6 + 1.days

    weekly_lumens = [lumens_on_date(t_1), lumens_on_date(t_2), lumens_on_date(t_3), lumens_on_date(t_4), lumens_on_date(t_5), lumens_on_date(t_6), lumens_on_date(t_7)]
  end

  #Constructs array of color values which determine which coloor to assign to particular weekly Lumen value on the front-end.
  def weekly_lumen_color_values(weekly_lumens)
    color_values = [] 
    weekly_lumens.each {|l| color_values << color_value_assignment(l)}
    color_values
  end

  #Determining color values ranges
  def color_value_assignment(value)
    if value == 0
      0
    elsif value.between(1 , 2)
      1
    elsif value.between(3, 7)
      2
    elsif value.between(8, 16)
      3
    elsif value.between(17, 32)
      4
    elsif value.between(33, 64)
      5
    elsif value.between(65, 128)
      6
    else 
      7
    end
  end

  #2-D array containing the Lumen value of a day and the corresponding color value
  def lumen_pacakge
    package = weekly_lumens.zip(weekly_lumen_color_values(weekly_lumens))
  end

  #Extract Lumen Values for each user by instance and create according Lume Value objects. This is to backfill historical Lumen values.
  def populate_lumen_values 
    votes = LytitVote.where(user_id: self.id)
    for vote in votes
      l = LumenValues.new(:value => LumenConstants.votes_weight_adj, :user_id => self.id)
      l.created_at = vote.created_at
      l.save
    end

    comments = self.venue_comments
    for comment in comments
      views = CommentView.where(venue_comment_id: comment.id)
      for view in views
        adjusted_views = 2 ** ((- (view.created_at - comment.created_at) / 1.minute) / (LumenConstants.views_halflife))
        l2 = LumenValues.new(:value => (comment.consider*(comment.weight*adjusted_views*LumenConstants.views_weight_adj)).round(4), :user_id => self.id)
        l2.created_at = view.created_at
        l2.save
      end
    end
  end

  def lumens_percentile
    all_lumens = User.all.map { |user| user.lumens}
    percentile = all_lumens.percentile_rank(self.lumens)
  end

  def update_lumen_percentile
    all_lumens = User.all.map { |user| user.lumens}
    percentile = all_lumens.percentile_rank(self.lumens)
    update_columns(lumen_percentile: percentile)
  end

  def total_votes
    LytitVote.where(user_id: self.id).count
  end

  def total_video_comments
    VenueComment.where(user_id: self.id, media_type: "video").count
  end

  def total_image_comments
    VenueComment.where(user_id: self.id, media_type: "image").count
  end

  def total_text_comments
    VenueComment.where(user_id: self.id, media_type: "text").count
  end

  def total_comment_views
    count = 0
    comments = self.venue_comments
    comments.each {|comment| count += comment.total_views}
    count
  end

  #averager number of adjusted views received
  def avg_adj_views
    comments = self.venue_comments
    total_adjusted_views = 0
    total_considered_comments = 0

    for comment in comments
      if comment.consider == 1
        total_adjusted_views += comment.adj_views
        total_considered_comments += 1
      end
    end

    total_adjusted_views -= total_text_comments*LumenConstants.text_media_weight
    avg_adj_views = total_a_views / total_considered_comments
    avg_adj_views
  end

  #determines if a user's Lumen value is more of a function of posting frequency or intensity (as determined by views received)
  #returns 1 becuase it will be 1st of 5 categories of Lumen determinants, 3 because it will be 3rd (after volume of posted photos and videos)
  def lumen_views_contribution_rank
    if avg_adj_views >= 1/LumenConstants.views_weight_adj
      return 1
    else
      return 3
    end
  end

  def lumen_contribution_breakdown
    comments = self.venue_comments
    video_contribution = 0
    image_contribution = 0
    text_contribution = 0
    votes_contribution = self.total_votes*LumenConstants.votes_weight_adj
    ranking_array = []

    video_contribution = total_video_comments*LumenConstants.video_media_weight
    image_contribution = total_image_comments*LumenConstants.image_media_weight
    text_contribution = total_text_comments*LumenConstants.text_media_weight

    ranking_array << video_contribution
    ranking_array << image_contribution
    ranking_array << text_contribution
    ranking_array << votes_contribution

    (ranking_array.sort!).reverse!

    breakdown = Hash.new
    breakdown["video"] = ranking_array.index(video_contribution)+1
    breakdown["image"] = ranking_array.index(image_contribution)+1
    breakdown["text"] = ranking_array.index(text_contribution)+1
    breakdown["votes"] = ranking_array.index(votes_contribution)+1

    if lumen_views_contribution_rank == 1
      breakdown.each {|k, v| breakdown[k] = v+1}
    else
      breakdown.each do |k, v|
        if v >= 3
          breakdown[k] = v+1
        end
      end
    end

    breakdown["views"] = lumen_views_contribution_rank

    return breakdown
  end

  def lumen_video_contribution_rank
    rank = lumen_contribution_breakdown["video"]
  end

  def lumen_image_contribution_rank
    rank = lumen_contribution_breakdown["image"]
  end

  def lumen_text_contribution_rank
    rank = lumen_contribution_breakdown["text"]
  end

  def lumen_votes_contribution_rank
    rank = lumen_contribution_breakdown["votes"]
  end 


  private

  def generate_confirmation_token_for_venue_manager
    if role_id_changed?
      if role.try(:name) == "Venue Manager"
        self.confirmation_token = SecureRandom.hex
      end    
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
