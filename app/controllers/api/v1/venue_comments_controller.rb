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
			#view = CommentView.create!(:venue_comment_id => params[:venue_comment_id], :user_id => params[:user_id])
			vc.increment_geo_views(country, city)
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