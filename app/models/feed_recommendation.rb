class FeedRecommendation < ActiveRecord::Base
	belongs_to :feed

	def set_image_url
		last_venue_comment_url = self.feed.latest_image_thumbnail_url
		self.update_columns(image_url: last_venue_comment_url)
	end
end