require_relative 'production'

Mail.register_interceptor RecipientInterceptor.new(ENV['EMAIL_RECIPIENTS'])

LytitServer::Application.configure do
  # ...

  config.action_mailer.default_url_options = { host: 'lytit-lumen.herokuapp.com' }
end
