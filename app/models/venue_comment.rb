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

end
