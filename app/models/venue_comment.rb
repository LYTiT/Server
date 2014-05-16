class VenueComment < ActiveRecord::Base
  validates :comment, presence: true

  belongs_to :user
  belongs_to :venue

  has_many :flagged_comments, :dependent => :destroy
end
