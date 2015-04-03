class VenueComment < ActiveRecord::Base
  #validates :comment, presence: true

  belongs_to :user
  belongs_to :venue
  belongs_to :bounty_claim
  
  has_many :flagged_comments, :dependent => :destroy
  has_many :comment_views, :dependent => :destroy
  has_many :lumen_values
  has_many :groups_venue_comments, :dependent => :destroy
  has_many :groups, through: :groups_venue_comments

  validate :comment_or_media


  def link_to_groups!
    g_ids = GroupsVenue.where("venue_id = #{self.venue_id}").pluck(:group_id)
    g_ids.map{|target_group_id| GroupsVenueComment.create(venue_comment_id: self.id, group_id: target_group_id)}
  end

  def hashtags
    hashtags = "SELECT groups_id FROM groups_venue_comments WHERE venue_comment_id = #{self.id} AND is_hashtag = TRUE"
    hashtag_groups = Group.where("id IN (#{hastag})").to_a
  end

  def comment_or_media
    if self.comment.blank? and self.media_url.blank?
      errors.add(:comment, 'or image is required')
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

  #determines weight of venue comment for Lumen calculation
  def weight
    type = self.media_type

    if type == "text"
      LumenConstants.text_media_weight
    elsif type == "image"
      LumenConstants.image_media_weight
    else
      LumenConstants.video_media_weight
    end

  end

  #returns comments of users followed
  def VenueComment.from_users_followed_by(user)
    followed_users_ids = "SELECT followed_id FROM relationships WHERE follower_id = :user_id " #AND username_private = 'false' AND venue_id != 14002"
    where("user_id IN (#{followed_users_ids}) AND username_private = 'false' AND venue_id != 14002", user_id: user)
  end

  #returns comments of venues followed
  def VenueComment.from_venues_followed_by(user)
    ids_followed_by_user = "SELECT followed_id FROM relationships WHERE follower_id = #{user.id}" 

    if ids_followed_by_user.length > 0
      followed_venues_ids = "SELECT vfollowed_id FROM venue_relationships WHERE ufollower_id = :user_id AND user_id NOT IN (#{ids_followed_by_user}) AND user_id != :user_id"
      where("venue_id IN (#{followed_venues_ids})", user_id: user)
    else
      followed_venues_ids = "SELECT vfollowed_id FROM venue_relationships WHERE ufollower_id = :user_id AND user_id != :user_id"
      where("venue_id IN (#{followed_venues_ids})", user_id: user)
    end
  end

  def VenueComment.live_from_venues_followed_by(user)
    followed_venues_ids = "SELECT vfollowed_id FROM venue_relationships WHERE ufollower_id = #{user.id}"
    where("venue_id IN (#{followed_venues_ids}) AND (NOW() - created_at) <= INTERVAL '1 DAY' ").order("id desc")
  end

  def VenueComment.from_valid_bounty_claims(bounty)
    b_id = bounty.id
    valid_bounty_claim_ids = "SELECT id FROM bounty_claims WHERE bounty_id = #{b_id} AND rejected = false"
    where("bounty_claim_id IN (#{valid_bounty_claim_ids})").order("created_at desc")
  end

  def VenueComment.from_group_venues(group)
    group_venue_ids = "SELECT venue_id FROM groups_venues WHERE group_id = :group_id"
    where("venue_id in (#{group_venue_ids})", group_id: id)
  end

  def set_offset_created_at
    #note that offset time will still be stored in UTC, disregard the timezone
    if venue != nil
      offset = created_at.in_time_zone(venue.time_zone).utc_offset
      offset_time = created_at + offset
      update_columns(offset_created_at: offset_time)
    end
  end

  def consider?
    consider = 1
    previous_comment = user.venue_comments.order("created_at desc limit 2")[1]

    if previous_comment == nil
      update_columns(consider: consider)
      return consider
    else
      if (self.venue_id == previous_comment.venue_id) && ((self.created_at - previous_comment.created_at) >= (LumenConstants.posting_pause*60))
        consider = 1
      elsif self.venue_id != previous_comment.venue_id
        consider = 1
      else
        consider = 0
      end
    end
    update_columns(consider: consider)
    return consider
  end


end




