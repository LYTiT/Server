class ActivityFeed < ActiveRecord::Base
	belongs_to :feed
	belongs_to :activity

	def self.bulk_creation(target_activity_id, f_ids)
		f_ids.each{|f_id| ActivityFeed.create!(:activity_id => target_activity_id, :feed_id => f_id)}
	end

end