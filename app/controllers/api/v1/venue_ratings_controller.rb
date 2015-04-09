class Api::V1::VenueRatingsController < ApiBaseController
	def create
		@venue_rating = VenueRating.new(venue_rating_params)
		@venue_rating.venue = venue
		@venue_rating.user = @user

		if @venue_rating.save
			render json: @venue_rating
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: @venue_rating.errors.full_messages } }, status: :unprocessable_entity
		end
	end

	private

	def venue_rating_params
		params.permit(:rating)
	end

	def venue
		@venue ||= Venue.find(params[:venue_id])
	end
end
