class Api::V1::VenueCommentsController < ApiBaseController
	def get_venue_comment
		@venue_comment = VenueComment.find_by_id(params[:venue_comment_id])
	end

	def register_view
		city = params[:city]
		country = params[:country] 		
		vc = VenueComment.find_by_id(params[:venue_comment_id])
		view = CommentView.create!(:venue_comment_id => params[:venue_comment_id], :user_id => params[:user_id])

		if view 
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['View registered'] } }, status: :unprocessable_entity
		end
	end

	def report
		ro = ReportedObject.create!(:type=> "VenueComment", :venue_comment_id => params[:venue_comment_id], :reporter_id => params[:reporter_id])
		if ro 
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Report did not got through'] } }, status: :unprocessable_entity
		end
	end
end