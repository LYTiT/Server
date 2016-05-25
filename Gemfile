source 'https://rubygems.org'

ruby '2.2.2'

gem 'rails', '>= 4.0.0'
#Setup
gem 'clearance'
gem 'email_validator'
gem 'recipient_interceptor'
gem "paranoia", "~> 2.0"
gem 'acts_as_singleton'
#Server Configurators
gem 'rails_admin'#, "0.6.8"
gem 'heroku-api'
gem 'heroku-deflater', :group => :production
gem 'unicorn'
gem 'aws-sdk', '~> 1.5.7'
gem 'rack-timeout'
gem 'rufus-scheduler'
gem 'honeybadger'
gem 'delayed_job_active_record', '>= 4.0.0'
gem 'skylight'
gem 'whacamole'
#Database
gem 'pg'
gem 'postgresql_cursor'
gem 'pg_search', '= 1.0.3'
gem 'mongo'
gem 'mongo_mapper', :git => "git://github.com/mongomapper/mongomapper.git", :tag => "v0.13.0.beta2"
#JSON/Views
gem 'jbuilder'
gem 'multi_json'
gem 'topojson-rails'
gem 'kaminari'
gem 'bson_ext'
#Caching
gem 'dalli'
gem 'memcachier'
gem 'jbuilder_cache_multi'
#Geo
gem 'activerecord-postgis-adapter'
gem 'pr_geohash'
gem 'geocoder'
gem 'geokit-rails'
#timezones
gem 'timezone'
gem 'tzinfo'
#Scientific
gem 'rubypython', "0.6.3"
gem 'descriptive_statistics'
gem 'rubystats'
gem 'croupier'
#APIs
gem 'httparty'
gem 'instagram'
gem 'twitter'
gem 'foursquare2'
gem 'eventbrite'
#Language Processing
gem 'fuzzy-string-match' #text proximity matching
gem 'fuzzy_match'
gem 'amatch'
gem 'gingerice' #spell checker
gem 'graph-rank' #text trend rank
gem 'highscore' 
gem 'engtagger' #part of speach determiner
gem 'fast-stemmer'
#Front-end Related
gem 'sass-rails'
gem 'bourbon'
gem 'neat'
gem 'font-awesome-rails'
gem 'normalize-rails'
gem 'twitter-bootstrap-rails', :git => 'git://github.com/seyhunak/twitter-bootstrap-rails.git', :branch => 'bootstrap3'
gem "d3-rails"
gem 'jquery-rails'
gem 'jquery-ui-rails'#, github: 'joliss/jquery-ui-rails', branch: 'rails-4.0.2'
gem 'flutie'
gem 'title'
gem 'haml-rails'
gem 'simple_form'
gem "paperclip", "~> 4.1"
gem 'high_voltage'
gem 'coffee-rails'
gem 'uglifier'
#iOS Related
gem 'apns', git: 'https://github.com/jpoz/APNS.git'
#Other

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
