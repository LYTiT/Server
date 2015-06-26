class FeedVenue < ActiveRecord::Base
	belongs_to :feed
	belongs_to :user
	has_many :venues
end