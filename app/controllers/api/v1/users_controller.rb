class Api::V1::UsersController < ApiBaseController
  skip_before_filter :set_user

  def create
    @user = User.new(user_params)

    if @user.save
      sign_in @user
      render 'created.json.jbuilder'
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.permit(:name, :email, :password)
  end
end
