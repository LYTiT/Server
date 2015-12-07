class LiveUser < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue

	after_create :make_venue_live

	def make_venue_live
		self.venue.update_column(is_live: true)
	end
end