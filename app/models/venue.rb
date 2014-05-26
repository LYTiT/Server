class Venue < ActiveRecord::Base

  acts_as_mappable :default_units => :miles,
                     :default_formula => :sphere,
                     :distance_field_name => :distance,
                     :lat_column_name => :latitude,
                     :lng_column_name => :longitude

  validates :name, presence: true
  validates :latitude, presence: true
  validates :longitude, presence: true

  has_many :venue_ratings, :dependent => :destroy
  has_many :venue_comments, :dependent => :destroy

  has_many :groups_venues, :dependent => :destroy
  has_many :groups, through: :groups_venues

  has_many :events, :dependent => :destroy

  MILE_RADIUS = 2

  def self.search(params)
    if params[:full_query] && params[:q] && params[:lat] && params[:lng]
      Venue.fetch_venues(params[:q], params[:lat], params[:lng], self.miles_to_meters(MILE_RADIUS))
    else
      scoped = all
      if params[:lat] && params[:lng]
        scoped = scoped.within(MILE_RADIUS, :origin => [params[:lat], params[:lng]]).order('distance ASC')
      end

      scoped
    end
  end

  def self.google_venues(params)
    scoped = where("google_place_reference IS NOT NULL")

    if params[:lat] && params[:lng]
      scoped = scoped.within(MILE_RADIUS, :origin => [params[:lat], params[:lng]]).order('distance ASC')
    end

    scoped
  end

  def self.fetch_venues(q, latitude, longitude, meters = 2000)
    list = []
    client = Venue.google_place_client

    #radius in meters
    spots = client.spots_by_query(q, :radius => meters, :lat => latitude, :lng => longitude)
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
      list << venue.id if venue.persisted?
    end

    Venue.within(Venue.meters_to_miles(meters), :origin => [latitude, longitude]).order('distance ASC').where("id IN (?)", list)
  end

  def self.fetch_spot(google_reference_key)
    venue = Venue.where("google_place_reference = ?", google_reference_key).first
    if venue.blank?
      venue = Venue.new
      venue.google_place_reference = google_reference_key
    end
    venue.populate_google_address(true)
    venue
  end

  def populate_google_address(force = false)
    if force == true or !self.fetched_at.present? or ((Time.now - self.fetched_at) / 1.day).round > 4
      client = Venue.google_place_client
      spot = client.spot(self.google_place_reference)
      self.city = spot.city
      self.state = spot.region
      self.postal_code = spot.postal_code
      self.country = spot.country
      self.address = [ spot.street_number, spot.street].join(', ')
      self.fetched_at = Time.now
      self.save
    end
  end

  def self.google_place_client
    GooglePlaces::Client.new(ENV['GOOGLE_PLACE_API_KEY'])
  end

  def self.miles_to_meters(miles)
    miles * 1609.34
  end

  def self.meters_to_miles(meter)
    meter * 0.000621371
  end

end

#@client.spots(-33.8670522, 151.1957362, :radius => 100, :name => 'italian')
#@client.spots_by_query('italian', :radius => 1000, :lat => '-33.8670522', :lng => '151.1957362')