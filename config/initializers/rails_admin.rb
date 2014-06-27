RailsAdmin.config do |config|
  config.authenticate_with do
    if current_user.present? and not current_user.is_admin?
      unathorized
    elsif not current_user.present?
      session[:return_to] = '/admin'
      flash.notice = I18n.t('flashes.unauthenticated')
      redirect_to '/sign_in'
    end
  end

  config.excluded_models << "ExportedDataCsv"
  config.excluded_models << "VenuesCsv"
  config.excluded_models << "VotesCsv"
  config.excluded_models << "LytitBar"

  config.model 'User' do
    edit do
      field :password do
        help 'Required. Length of 8-128. <br />(leave blank if you don\'t want to change it)'.html_safe
      end
      field :password_confirmation do
        hide
      end
      include_all_fields
      field :venues do
        label 'Manage Venue(s)'
      end
    end
  end
  
  config.main_app_name { ['My App', 'Admin'] }
end
