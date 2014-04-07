namespace :dev do
  desc 'Creates sample data for local development'
  task load: ['db:setup'] do
    unless Rails.env.development?
      raise 'This task can only be run in the development environment'
    end

    require 'factory_girl_rails'
    require 'faker'

    create_venues
  end

  def create_venues
    header 'creating venues'
    10.times do
      Venue.create!(name: Faker::Company.name,
                   city: Faker::Address.city,
                   state: Faker::Address.state,
                   latitude: Faker::Address.latitude,
                   longitude: Faker::Address.longitude
                  )
    end
  end

  private

  def header(msg)
    puts "\n\n*** #{msg.upcase} *** \n\n"
  end
end
