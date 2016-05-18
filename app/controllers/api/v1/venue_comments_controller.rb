class Api::V1::VenueCommentsController < ApiBaseController
	def get_venue_comment
		@venue_comment = VenueComment.find_by_id(params[:venue_comment_id])
	end

	def register_view
		city = params[:user_city]
		country = params[:user_country]		
		vc = VenueComment.find_by_id(params[:venue_comment_id])	
		if vc 			
			if CommentView.find_by_venue_comment_id_and_user_id(params[:venue_comment_id], params[:user_id]) == nil and (vc.user_id != params[:user_id])
				User.find_by_id(vc.user_id).increment!(:num_bolts, 1)
				#vc.increment_geo_views(country, city, params[:user_lat], params[:user_long])
				view = CommentView.create!(:venue_comment_id => params[:venue_comment_id], :user_id => params[:user_id])				
			end
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['View not registered'] } }, status: :unprocessable_entity
		end
	end

	def report
		ro = ReportedObject.create!(:report_type=> "Report Moment", :venue_comment_id => params[:venue_comment_id], :reporter_id => params[:user_id])
		if ro 
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Report did not got through'] } }, status: :unprocessable_entity
		end
	end

	def delete_post
		vc = VenueComment.find_by_id(params[:venue_comment_id])
		@user = User.find_by_authentication_token(params[:auth_token])
		if @user.id == vc.user_id || @user.role_id == 1
			if vc.venue.venue_comment_details["id"] == vc.id
				second_latest_vc = vc.venue.venue_comments.order("adjusted_sort_position DESC").limit(1).offset(1)
				vc.venue.update_featured_comment(vc)
			end
			vc.destroy
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['User can only delete his/her posts.'] } }, status: :unprocessable_entity
		end
	end

	def evaluate
		vc = VenueComment.find_by_id(params[:venue_comment_id])
		if vc.evaluate(params[:user_id], params[:enlytened] == "1", params[:city], params[:country], params[:latitude], params[:longitude])
			render json: { success: true}
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Post not evaluated successfully'] } }, status: :unprocessable_entity
		end
	end

end