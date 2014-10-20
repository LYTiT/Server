class VenueComment < ActiveRecord::Base
  #validates :comment, presence: true

  belongs_to :user
  belongs_to :venue

  has_many :flagged_comments, :dependent => :destroy

  validate :comment_or_media

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

  def total_adj_views
    if self.media_type == 'text'
      total = 1
    else
      views = CommentView.where(venue_comment_id: self.id)
      total = 0
      views.each {|view| total += 2 ** ((- (view.created_at - self.created_at) / 1.minute) / (LumenConstants.views_halflife))}
      total
    end
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
    followed_users_ids = "SELECT followed_id FROM relationships WHERE follower_id = :user_id AND username_private = 'false'"
    where("user_id IN (#{followed_users_ids})", user_id: user)
  end

  def VenueComment.from_venues_followed_by(user)
    #followed_venues_ids = "SELECT vfollowed_id FROM venue_relationships WHERE ufollower_id = :user_id"
    #where("user_id IN (#{followed_venues_ids})", user_id: user)
    #followed_venues_ids = user.followed_venues_ids
    #where("user_id IN (?)", vfollowed_ids, user) 
    comments = where("venue_id IN (?)", user.followed_venues.ids)
  end

  def consider?
    consider = 1
    user = User.find_by(id: self.user_id)
    comments = user.venue_comments
    hash = Hash[comments.map.with_index.to_a]
    index = hash[self]

    if index == 0 
      consider

    else  
      previous = comments[(index-1)]

      if (self.venue_id == previous.venue_id) and ((self.created_at - previous.created_at) >= (LumenConstants.posting_pause*60))
        consider
      elsif self.venue_id != previous.venue_id
        consider
      else
        consider = 0
      end

    end
    #update_columns(consider: consider)
  end


end




