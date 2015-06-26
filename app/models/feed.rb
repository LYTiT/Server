class Feed < ActiveRecord::Base
	belongs_to :user
	has_many :feed_venues, :dependent => :destroy
	has_many :venues, through: :feed_venues

	def comments
		venue_ids = "SELECT venue_id FROM feeds WHERE id = #{self.id}"
		comments = VenueComment.where("venue_id IN (#{venue_ids}) AND (NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")
	end

end