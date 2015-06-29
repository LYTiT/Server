class Feed < ActiveRecord::Base
	belongs_to :user
	has_many :feed_venues, :dependent => :destroy
	has_many :venues, through: :feed_venues
	has_many :venue_comments, through: :venues

	def comments
		venue_ids = "SELECT venue_id FROM feeds WHERE id = #{self.id}"
		comments = VenueComment.where("venue_id IN (#{venue_ids}) AND (NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")
	end

	def is_venue_present?(v_id)
		FeedVenue.where("feed_id = ? AND venue_id = ?", self.id, v_id).any?
	end

	def new_content_present?
		latest_viewed_time_wrapper = latest_viewed_time || (Time.now + 1.minute)
		self.venue_comments.where("venue_comments.created_at > ?", latest_viewed_time_wrapper).count
	end

	def update_media
		self.venues.each do |v|
			v.instagram_pull_check
		end
	end

end