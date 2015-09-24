class FeedRecommendation < ActiveRecord::Base
	belongs_to :feed

	has_many :feed_activities, :dependent => :destroy
	after_create :create_feed_acitivity

	def create_feed_acitivity
		FeedActivity.create!(:feed_id => feed_id, :type => "made spotlyt", :feed_recommendation_id => self.id, :adjusted_sort_position => (self.created_at + 24.hours).to_i)
	end

	def set_image_url
		last_venue_comment_url = self.feed.latest_image_thumbnail_url
		self.update_columns(image_url: last_venue_comment_url)
	end
end