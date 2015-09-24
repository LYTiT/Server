class FeedActivity < ActiveRecord::Base
	belongs_to :feed
	belongs_to :venue_comment
	belongs_to :feed_venue
	belongs_to :feed_user
	belongs_to :feed_message
	belongs_to :like
	belongs_to :feed_recommendation

	def self.create_new_venue_comment_activities(vc)
		feed_ids = "SELECT feed_id FROM feed_venues WHERE venue_id = #{vc.venue_id}"
		feeds_with_venue = Feed.where("id IN (#{feed_ids})")
		feeds_with_venue.each{|feed_with_venue| FeedActivity.create!(:feed_id => feed_with_venue.id, :activity_type => "venue comment", :venue_comment_id => vc.id, :adjusted_sort_position => vc.created_at.to_i)}
	end

end
