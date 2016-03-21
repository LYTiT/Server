class FavoriteVenue < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue

	def FavoriteVenue.top_user_favorites(u_id)
		FavoriteVenue.where("user_id = ?", u_id).order("interest_score * (SELECT popularity_rank FROM venues WHERE id = favorite_venues.venue_id) DESC").limit(5)
	end
end