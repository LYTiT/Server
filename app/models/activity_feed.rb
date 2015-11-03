class ActivityFeed < ActiveRecord::Base
	belongs_to :feed
	belongs_to :activity

	def self.populate
		total_activity = Activity.all
		total_activity.each{|activity| ActivityFeed.create!(:activity_id => activity.id, :feed_id => activity.feed_id)}
	end

end