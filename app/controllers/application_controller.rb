class ApplicationController < ActionController::Base
  include Clearance::Controller
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery

  private

  def ssl_configured?
    !Rails.env.development?
  end

  def authorize
    unless signed_in?
      deny_access(I18n.t('flashes.unauthenticated'))
    end
  end

  def unathorized
    render :file => "public/401.html", :status => :unauthorized, :layout => false
    return
  end

end
