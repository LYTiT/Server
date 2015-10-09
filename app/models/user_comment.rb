class UserComment < ActiveRecord::Base
	belongs_to :user
	belongs_to :feed_activity
end