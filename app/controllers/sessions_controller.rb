class SessionsController < Clearance::SessionsController

  force_ssl only: [:new, :create], if: :ssl_configured?

  def create
    @user = authenticate(params)

    sign_in(@user) do |status|
      if status.success? and @user.present? and @user.is_venue_manager? and @user.venues.present?  
        redirect_to venue_path(@user.venues.first)
      else
        flash.now.notice = status.try(:failure_message) || I18n.t('flashes.failure_after_create')
        render template: 'sessions/new', status: :unauthorized
      end
    end
  end

  def new
    if signed_in?
      if current_user.is_venue_manager? and current_user.venues.present? 
        redirect_to venue_path(current_user.venues.first)
      else
        redirect_to sign_out_path
      end
    else
      render template: 'sessions/new'
    end
  end

end
