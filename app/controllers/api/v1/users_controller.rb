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

  def update
    @user = User.find params[:id]
    user_params.delete(:password)

    if @user.update_attributes(user_params)
      render 'created.json.jbuilder'
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.permit(:name, :email, :password, :notify_location_added_to_groups, :notify_events_added_to_groups)
  end
end
