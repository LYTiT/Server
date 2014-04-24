class Api::V1::UsersController < ApiBaseController
  #skip_before_filter :set_user

  def create
    @user = User.new(user_params)

    if @user.save
      sign_in @user
      render 'created.json.jbuilder'
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def get_comments
    @user = User.find_by_id(params[:user_id])
    if @user
      render json: @user.venue_comments
    else
      render json: {:error => "not-found"}.to_json, :status => 404
    end
  end

  private

  def user_params
    params.permit(:name, :email, :password)
  end
end
