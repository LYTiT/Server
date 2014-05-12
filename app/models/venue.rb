class Venue < ActiveRecord::Base
  validates :name, presence: true
  validates :latitude, presence: true
  validates :longitude, presence: true

  has_many :venue_ratings, :dependent => :destroy
  has_many :venue_comments, :dependent => :destroy

  has_many :groups_venues, :dependent => :destroy
  has_many :groups, through: :groups_venues

  has_many :events, :dependent => :destroy

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

    #radius in meters
    spots = client.spots_by_query(q, :radius => 2000, :lat => latitude, :lng => longitude)
    spots.each do |spot|
      venue = Venue.where("google_place_key = ?", spot.id).first
      venue ||= Venue.new()
      venue.name = spot.name
      venue.google_place_key = spot.id
      venue.google_place_rating = spot.rating
      venue.google_place_reference = spot.reference
      venue.latitude = spot.lat
      venue.longitude = spot.lng
      venue.formatted_address = spot.formatted_address
      venue.city = spot.city
      venue.save
      list << venue if venue.persisted?
    end
    list
  end

  def populate_google_address
    client = Venue.google_place_client
    spot = client.spot(self.google_place_reference)
    self.city = spot.city
    self.state = spot.region
    self.postal_code = spot.postal_code
    self.country = spot.country
    self.address = [ spot.street_number, spot.street].join(', ')
    #spot.address_components.each do |a|
      #address << a['long_name'] if !a['types'].include?('country') and !a['types'].include?('postal_code')
      #end
    #self.address = address.join(', ')
    self.save
  end

  def self.google_place_client
    GooglePlaces::Client.new(ENV['GOOGLE_PLACE_API_KEY'])
  end

end

#@client.spots(-33.8670522, 151.1957362, :radius => 100, :name => 'italian')
#@client.spots_by_query('italian', :radius => 1000, :lat => '-33.8670522', :lng => '151.1957362')