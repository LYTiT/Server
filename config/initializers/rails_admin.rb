RailsAdmin.config do |config|
  config.authorize_with do
    authenticate_or_request_with_http_basic('Site Message') do |username, password|
      username == 'lytit' && password == 'happyfun'
    end
  end

  config.model 'User' do
    edit do
      field :password do
        help 'Required. Minimum 8 characters. (leave blank if you don\'t want to change it)'
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
