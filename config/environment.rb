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

# acts_as_singleton gem is raising a strange NoMethodError when
# calling the position method the first time after app starts up

#begin
#  LytitBar.instance.position
#rescue NoMethodError => e
  # do nothing actually, it should work from now on... O.o
#  puts e
#  LytitBar.instance.position # just to make sure :)
#end

