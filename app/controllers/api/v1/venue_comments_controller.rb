class Api::V1::VenueCommentsController < ApiBaseController
	def get_venue_comment
		@venue_comment = VenueComment.find_by_id(params[:venue_comment_id])
	end

	def register_view
		venue_comment = VenueComment.find_by_id(params[:venue_comment_id])
	end
end