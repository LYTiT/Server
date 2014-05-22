class ApiBaseController < ApplicationController

  protect_from_forgery with: :null_session

  before_filter :set_user
  skip_before_filter  :verify_authenticity_token

  rescue_from Exception, :with => :handle_public_excepton

  protected

  def handle_public_excepton(e)
    logger.error e.inspect
    render json: { errors: [e.message] }
  end

  private

  def set_user
    @user = User.find_by_authentication_token(params[:auth_token])
    unless @user
      render json: {:errors => ['User is invalid']}, status: :unprocessable_entity
    end
  end
end
