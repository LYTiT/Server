class PasswordsController < Clearance::PasswordsController

  force_ssl if: :ssl_configured?

  def update
    @user = find_user_for_update

    if @user.update_password password_reset_params
      flash[:message] = "Your password has been successfully reset."
      redirect_to "/"
    else
      flash_failure_after_update
      render template: 'passwords/edit'
    end
  end

end