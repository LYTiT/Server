class Api::V1::PostPassesController < ApiBaseController
	
	def pass_on
		pp = PostPass.find_by_id(params[:post_pass_id])	
		if pp
			pp.pass_on
			pp.venue_comment.evaluate(params[:user_id], true, params[:user_city], params[:user_country], params[:user_lat], params[:user_long])
			render json: { success: true }	
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: "No Post Pass Found" } }, status: :unprocessable_entity
		end
	end

	def terminate
		pp = PostPass.find_by_id(params[:post_pass_id])	
		if pp
			pp.terminate
			render json: { success: true }	
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: "No Post Pass Found" } }, status: :unprocessable_entity
		end
	end

	def report 
		pp = PostPass.find_by_id(params[:post_pass_id])	
		if pp
			pp.report
			render json: { success: true }	
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: "No Post Pass Found" } }, status: :unprocessable_entity
		end
	end
end