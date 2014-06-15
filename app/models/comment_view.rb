class CommentView < ActiveRecord::Base

  belongs_to :venue_comment
  belongs_to :user

  validates :venue_comment, presence: true
  validates :user, presence: true
  validates_uniqueness_of :user_id, :scope => :venue_comment_id, message: "User has all ready viewed this post"

end
