class Api::V1::SessionsController < ApiBaseController
  skip_before_filter :set_user

  def create
    @user = User.authenticate(params[:email], params[:password])
    if @user.nil?
      render json: {:message => 'User not found'}, status: :unprocessable_entity
    else
      sign_in @user
      render 'api/v1/users/created.json.jbuilder'
    end
  end
end
