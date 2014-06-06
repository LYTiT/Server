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
end
