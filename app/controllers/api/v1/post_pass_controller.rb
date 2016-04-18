class Api::V1::NotificationsController < ApiBaseController
	
	def pass_on
		pp = PostPass.find_by_id(param[:post_pass_id])	
		if pp
			pp.pass_on
			render json: { success: true }	
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: "No Post Pass Found" } }, status: :unprocessable_entity
		end
	end

	def terminate
		pp = PostPass.find_by_id(param[:post_pass_id])	
		if pp
			pp.terminate
			render json: { success: true }	
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: "No Post Pass Found" } }, status: :unprocessable_entity
		end
	end

	def report 
		pp = PostPass.find_by_id(param[:post_pass_id])	
		if pp
			pp.report
			render json: { success: true }	
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: "No Post Pass Found" } }, status: :unprocessable_entity
		end
	end
end