# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
LytitServer::Application.initialize!


ActionMailer::Base.smtp_settings = {
  :address        => 'smtp.sendgrid.net',
  :port           => '587',
  :authentication => :plain,
  :user_name      => ENV['SENDGRID_USERNAME'],
  :password       => ENV['SENDGRID_PASSWORD'],
  :domain         => 'heroku.com',
  :enable_starttls_auto => true
}

APNS.host = 'gateway.push.apple.com'
APNS.pem  = "#{Rails.root}/" + "pem_certificates/PushProdCertCombined.pem"
APNS.port = 2195
APNS.pass = 'lytit'
