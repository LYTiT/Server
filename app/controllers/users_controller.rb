class UsersController < ApplicationController

  def set_password
    sign_out
    @user = User.find_by_id_and_confirmation_token!(params[:user_id], params[:token])
  end

  def confirm_account
    @user = User.find_by_id_and_confirmation_token!(params[:user_id], params[:token]) 
    if @user.update_password(set_password_params)
      if @user.is_venue_manager? and @user.venues.present?  
        sign_in @user
        redirect_to venue_path(@user.venues.first)
      else
        unathorized
      end
    else
      flash.now.notice = "Password #{@user.errors.messages[:password].join(" and ")}"
      render :set_password
    end
  end

  def validate_email
    @user = User.find_by_id_and_confirmation_token!(params[:user_id], params[:token])
    if @user
      @user.validate_email
      flash[:notice] = "Email confirmed! You are entitled to the Lumen Game prize."
      redirect_to root_path
    else
      flash[:error] = "Sorry. User does not exist"
      #redirect_to "/"
    end

  end

  private

  def set_password_params
    params[:set_password][:password]
  end

end