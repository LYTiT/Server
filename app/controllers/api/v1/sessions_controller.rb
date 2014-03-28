class Api::V1::SessionsController < ApplicationController
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
