class Api::V1::VenueCommentController < ApiBaseController
	def get_details
		@venue_comment = VenueComment.find_by_id(params[:venue_comment_id])
		@user = @venue_comment.user
	end
end