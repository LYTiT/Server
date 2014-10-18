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

   #LUMEN Calculation
  def update_lumens()
    comments = self.venue_comments
    lumens = self.total_votes*LumenConstants.votes_weight_adj

    for comment in comments
      if(comment.media_type == 'text')
        lumens += comment.total_adj_views*comment.consider*LumenConstants.views_weight_adj*LumenConstants.text_media_weight
      
      elsif(comment.media_type == 'image')
        lumens += comment.total_adj_views*comment.consider*LumenConstants.views_weight_adj*LumenConstants.image_media_weight

      else
        lumens += comment.total_adj_views*comment.consider*LumenConstants.views_weight_adj*LumenConstants.video_media_weight

      end
    end

  end

  def total_votes
    LytitVote.where(user_id: self.id).count
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
