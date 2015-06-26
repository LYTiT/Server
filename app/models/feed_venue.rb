class FeedVenue < ActiveRecord::Base
	belongs_to :feed
	belongs_to :user
	belongs_to :venue
end