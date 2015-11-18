class Api::V1::SupportIssuesController < ApiBaseController

	def get_support_issues
		@user = User.find_by_authentication_token(params[:auth_token])
		if @user.is_admin? == true
			@issues = SupportIssue.where("latest_message_time IS NOT NULL").all.order("latest_message_time DESC").page(params[:page]).per(10)
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: "User is not an admin" } }, status: :unprocessable_entity
		end
	end

	def get_support_chat
		@user = User.find_by_authentication_token(params[:auth_token])
		if @user.is_admin? == true
			support_issue = SupportIssue.find_by_id(params[:support_issue_id])
			support_issue.update_columns(latest_open_time: Time.now)						
		else
			support_issue = @user.support_issue
		end

		support_messages = support_issue.support_messages.order("id DESC")
		@messages = support_messages.page(params[:page]).per(10)
	end

	def send_support_message
		@user = User.find_by_authentication_token(params[:auth_token])
		if @user.is_admin? == true
			support_issue_id = params[:support_issue_id]
		else
			user_support_issue = @user.support_issue
			if user_support_issue != nil
				support_issue_id = user_support_issue.id
			else
				new_support_issue = SupportIssue.create!(:user_id => @user.id)
				support_issue_id = new_support_issue.id
			end
		end		

		sm = SupportMessage.create!(:message => params[:message], :support_issue_id => support_issue_id, :user_id => @user.id)
		if sm != nil
			render json: { success: true }	
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: "Support message sending issue" } }, status: :unprocessable_entity
		end
	end

end