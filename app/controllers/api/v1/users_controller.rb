class Api::V1::UsersController < ApiBaseController
  skip_before_filter :set_user, only: [:create, :get_comments, :get_groups, :forgot_password]

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
    if not @user
      render json: {:error => "not-found"}.to_json, :status => 404
    end
  end

  def get_groups
    @user = User.find_by_id(params[:user_id])
    if not @user
      render json: {:error => "not-found"}.to_json, :status => 404
    end
  end

  def update
    @user = User.find params[:id]
    permitted_params = user_params
    permitted_params.delete(:password)

    if @user.update_attributes(permitted_params)
      render 'created.json.jbuilder'
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def register_push_token
    @user.push_token = params[:push_token]
    @user.save
    render 'created.json.jbuilder'
  end

  def change_password
    if User.authenticate(@user.email, params[:old_password])
      if @user.update_password(params[:new_password])
        render 'created.json.jbuilder'
      else
        render json: @user.errors, status: :unprocessable_entity
      end
    else
      render json: { :errors => ['Old password do not match'] }, status: :unprocessable_entity
    end
  end

  def toggle_group_notification
    @user.toggle_group_notification(params[:group_id], params[:enabled])
    render json: { success: true }
  end

  def forgot_password
    user = User.find_by_email(params[:email])
    if user
      user.forgot_password!
      ::ClearanceMailer.change_password(user).deliver
      render json: { success: true, message: 'Password reset link sent to your email.' }
    else
      render json: { :errors => ['Can not find user with this email'] }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.permit(:name, :email, :password, :notify_location_added_to_groups, :notify_events_added_to_groups)
  end
end
