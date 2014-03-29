RailsAdmin.config do |config|
  config.authorize_with do
    authenticate_or_request_with_http_basic('Site Message') do |username, password|
      username == 'lytit' && password == 'happyfun'
    end
  end

  config.main_app_name { ['My App', 'Admin'] }
end
