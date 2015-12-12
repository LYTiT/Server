class LiveUser < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue

	after_create :make_venue_live

	def self.cleanup
		live_users = LiveUser.where("created_at < ?" Time.now-45.minutes).includes(:venue)
		for live_user in live_users
			live_user.venue.update_columns(is_live: false)
			live_user.delete
		end
	end

	def make_venue_live
		self.venue.update_columns(is_live: true)
	end
end
