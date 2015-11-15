class Api::V1::SessionsController < ApiBaseController
	skip_before_filter :set_user

	def create
		@user = User.authenticate_by_username(params[:name], params[:password])
		if @user.nil?
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Incorrect username or password'] } }, status: :unprocessable_entity
		else
			@user.update_columns(active: true)
			sign_in @user
			render 'api/v1/users/created.json.jbuilder'
		end
	end

end
