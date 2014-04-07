class ApiBaseController < ApplicationController

  protect_from_forgery with: :null_session

  before_filter :set_user

  private

  def set_user
    @user = User.find_by_authentication_token(params[:auth_token])
    unless @user
      render json: {:errors => ['User is invalid']}, status: :unprocessable_entity
    end
  end
end
