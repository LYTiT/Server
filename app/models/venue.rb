class Venue < ActiveRecord::Base
  validates :name, presence: true
  validates :latitude, presence: true
  validates :longitude, presence: true

  has_many :venue_ratings
  has_many :venue_comments

  def self.search(params)

    scoped = all

    if params[:lat] && params[:lng]
      search = Search.new(params[:lat], params[:lng])
      scoped.where!("latitude < '#{search.ne_lat}' AND latitude > '#{search.sw_lat}'")
      scoped.where!("longitude < '#{search.ne_lng}' AND longitude > '#{search.sw_lng}'")
    end

    scoped
  end
  
  def self.fetch_venues(q, latitude, longitude)
    list = []
    client = Venue.google_place_client
    spots = client.spots(latitude, longitude, :name => q, :radius => 2000) #radius in meters
    spots.each do |spot|
      venue = Venue.where("google_place_key = ?", spot.id).first
      venue ||= Venue.new()
      venue.name = spot.name
      venue.google_place_key = spot.id
      venue.google_place_rating = spot.rating
      venue.latitude = spot.lat
      venue.longitude = spot.lng
      venue.address = [spot.street_number, spot.street].join(' ')
      venue.city = spot.city
      venue.save 
      list << venue if venue.persisted?
    end
    list
  end
  
  def self.google_place_client
    GooglePlaces::Client.new(ENV['GOOGLE_PLACE_API_KEY'])
  end
  
end

#@client.spots(-33.8670522, 151.1957362, :radius => 100, :name => 'italian')