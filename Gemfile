source 'https://rubygems.org'

ruby '2.2.2'

gem 'clearance'
gem 'coffee-rails'
gem 'delayed_job_active_record', '>= 4.0.0'
gem 'email_validator'
gem 'flutie'
gem 'high_voltage'
gem 'jbuilder'
gem 'jquery-rails'
gem 'pg'
gem 'rack-timeout'
gem 'rails', '>= 4.0.0'
gem 'rails_admin'#, "0.6.8"
gem 'recipient_interceptor'
gem 'simple_form'
gem 'title'
gem 'uglifier'
gem 'unicorn'
gem "paranoia", "~> 2.0"
gem 'haml-rails'
gem 'geokit-rails'
gem 'apns', git: 'https://github.com/jpoz/APNS.git'
#gem 'higcm'
gem 'rufus-scheduler'
gem 'rubypython', "0.6.3"
gem 'honeybadger'
gem 'jquery-ui-rails'#, github: 'joliss/jquery-ui-rails', branch: 'rails-4.0.2'
gem 'acts_as_singleton'
gem "paperclip", "~> 4.1"
gem 'aws-sdk', '~> 1.5.7'
gem 'mongo_mapper', :git => "git://github.com/mongomapper/mongomapper.git", :tag => "v0.13.0.beta2"
gem 'bson_ext'
gem 'mongo'
gem 'kaminari'
gem 'descriptive_statistics'
gem 'geocoder'
gem 'pr_geohash'
gem 'timezone'
#gem 'typhoeus'
gem 'tzinfo'
gem 'skylight'
gem 'heroku-deflater', :group => :production
gem 'instagram'
gem 'httparty'
gem 'fuzzy-string-match'
gem 'dalli'
gem 'memcachier'
gem 'whacamole'
gem 'heroku-api'
gem 'jbuilder_cache_multi'
gem 'twitter'
gem 'kdtree'
gem 'postgresql_cursor'
gem 'pg_search', '= 1.0.3'
gem 'activerecord-postgis-adapter'
gem 'foursquare2'
gem 'eventful_api'
gem 'multi_json'
gem 'eventbrite'

# design
gem 'sass-rails'
gem 'bourbon'
gem 'neat'
gem 'font-awesome-rails'
gem 'normalize-rails'
gem 'twitter-bootstrap-rails', :git => 'git://github.com/seyhunak/twitter-bootstrap-rails.git', :branch => 'bootstrap3'
gem 'topojson-rails'
gem "d3-rails"

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'foreman'
  gem 'spring'
  gem 'spring-commands-rspec'
end

group :development, :test do
  gem 'therubyracer'
  gem 'dotenv-rails'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'pry-byebug'
  gem 'rspec-rails', '>= 2.14'
  gem 'timecop'
end

group :test do
  gem 'capybara-webkit', '>= 1.0.0'
  gem 'database_cleaner'
  gem 'launchy'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'webmock'
end

group :staging, :production do
  gem 'rails_12factor'
  gem 'newrelic_rpm', '>= 3.6.7'
end
