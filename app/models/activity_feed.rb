class ActivityFeed < ActiveRecord::Base
	belongs_to :feed
	belongs_to :activity

	def self.populate
		total_activity = Activity.all
		total_activity.each{|activity| ActivityFeed.create!(:activity_id => activity.id, :feed_id => activity.feed_id)}
	end

	def self.bulk_creation(target_activity_id, f_ids)
		feed_ids.each{|f_id| ActivityFeed.create!(:activity_id => target_activity_id, :feed_id => f_id)}
	end

end