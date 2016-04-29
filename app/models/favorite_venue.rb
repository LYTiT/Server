class FavoriteVenue < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue

	def num_new_moments_for_user
		new_moment_count = self.venue.venue_comments.where("created_at > ?", latest_check_time).count
		self.update_columns(num_new_moments: new_moment_count)
		self.update_columns(latest_check_time: Time.now)
	end

	def FavoriteVenue.num_new_moment_reset
		FavoriteVenue.where("latest_check_time < ?", Time.now - 15.minutes).update_all(num_new_moments: 0)
	end

end