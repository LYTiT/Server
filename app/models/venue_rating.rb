class VenueRating < ActiveRecord::Base
  belongs_to :venue
  belongs_to :user

  validates :venue, presence: true
  validates :user, presence: true
  validates :rating, presence: true
end
