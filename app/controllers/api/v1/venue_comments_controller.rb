class Api::V1::VenueCommentsController < ApiBaseController
	def get_venue_comment
		@venue_comment = VenueComment.find_by_id(params[:venue_comment_id])
	end

	def register_view
		city = params[:user_city]
		country = params[:user_country]		
		vc = VenueComment.find_by_id(params[:venue_comment_id])	
		if vc 
			User.find_by_id(params[:user_id]).increment!(:num_bolts, 1)
			if CommentView.find_by_venue_comment_id_and_user_id(params[:venue_comment_id], params[:user_id]) != nil and (vc.user_id != params[:user_id])
				view = CommentView.create!(:venue_comment_id => params[:venue_comment_id], :user_id => params[:user_id])
				vc.increment_geo_views(country, city)
			end
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['View not registered'] } }, status: :unprocessable_entity
		end
	end

	def report
		ro = ReportedObject.create!(:type=> "Report Moment", :venue_comment_id => params[:venue_comment_id], :reporter_id => params[:reporter_id])
		if ro 
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Report did not got through'] } }, status: :unprocessable_entity
		end
	end

	def delete_post
		vc = VenueComment.find_by_id(params[:venue_comment_id])
		if params[:user_id] == vc.user_id
			vc.destroy
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['User can only delete his/her posts.'] } }, status: :unprocessable_entity
		end
	end
end