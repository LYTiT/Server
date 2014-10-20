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
    new_lumens = self.lumens+LumenConstants.votes_weight_adj
    update_columns(lumens: new_lumens)
  end

  def update_lumens_after_view(comment)
    new_lumens = self.lumens+comment.consider*(comment.weight*comment.total_adj_views*LumenConstants.views_weight_adj)
    update_columns(lumens: new_lumens)
  end

   #Lumen Calculation
  def calculate_lumens()
    comments = self.venue_comments
    lumens = self.total_votes*LumenConstants.votes_weight_adj

    comments.each {|comment| lumens += comment.consider*(comment.weight*comment.total_adj_views*LumenConstants.views_weight_adj)}
    update_columns(lumens: lumens)
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
    total_a_views = 0
    total_considered_comments = 0

    for comment in comments
      if comment.consider == 1
        total_a_views += comment.total_adj_views
        total_considered_comments += 1
      end
    end

    total_a_views -= total_text_comments*LumenConstants.text_media_weight
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
