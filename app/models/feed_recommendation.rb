class FeedRecommendation < ActiveRecord::Base
	belongs_to :feed

	def set_image_url
		last_venue_comment_url = self.feed.last_venue_comments.order("id DESC LIMIT 1").lowest_resolution_image_avaliable
		self.update_columns(image_url: last_venue_comment_url)
	end
end