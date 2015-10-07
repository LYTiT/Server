class Api::V1::SupportIssuesController < ApiBaseController

	def get_support_issues
		@user = User.find_by_authentication_token(params[:auth_token])
		if @user.role == "Admin"
			@issues = Kaminari.paginate_array(SupportIssue.all.order("latest_message_time DESC")).page(params[:page]).per(10)
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: "User is not an admin" } }, status: :unprocessable_entity
		end
	end

	def get_support_chat
		support_issue = SupportIssue.find_by_id(params[:support_issue_id])
		@user = User.find_by_authentication_token(params[:auth_token])
		if @user.role == "Admin"
			support_issue.update_columns(latest_open_time: Time.now)
		end
		support_messages = support_issue.support_messages.order("id DESC")
		@messages = Kaminari.paginate_array(support_messages).page(params[:page]).per(10)
	end

	def send_support_message
		@user = User.find_by_authentication_token(params[:auth_token])
		sm = SupportMessage.create!(:message => params[:message], :support_issue_id => params[:support_issue_id])
		if sm != nil
			render json: { success: true }	
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: "Support message sending issue" } }, status: :unprocessable_entity
		end
	end

end