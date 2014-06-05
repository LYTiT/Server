class SessionsController < Clearance::SessionsController

  force_ssl only: [:new, :create], if: :ssl_configured?

  def create
    @user = authenticate(params)
    sign_in(@user) do |status|
      if status.success?
        if @user.present? and @user.is_venue_manager? and @user.venues.present?  
          if session[:return_to].present?
            return_to = session[:return_to]
            session[:return_to] = nil
            redirect_to return_to
          else
            redirect_to venue_path(@user.venues.first)
          end
        elsif @user.present? and @user.is_admin?
          redirect_to '/admin'
        else
          sign_out
          unathorized
        end
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
      elsif current_user.present? and current_user.is_admin?  
        redirect_to '/admin'
      else
        redirect_to sign_out_path
      end
    else
      render template: 'sessions/new'
    end
  end

end
