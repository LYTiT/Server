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

  has_many :lytit_votes, :dependent => :destroy
  has_many :votes, :through => :lytit_votes

  def self.search(params)
    scoped = all
    if params[:lat] && params[:lng]
      scoped = scoped.within(2, :origin => [params[:lat], params[:lng]]).order('distance ASC')
    end

    scoped
  end

  def self.google_venues(params)
    scoped = where("google_place_reference IS NOT NULL")

    if params[:lat] && params[:lng]
      scoped = scoped.within(2, :origin => [params[:lat], params[:lng]]).order('distance ASC')
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
      list << venue.id if venue.persisted?
    end

    # 1.242 miles == 2000 meters
    Venue.within(1.242, :origin => [latitude, longitude]).order('distance ASC')
  end

  def self.fetch_spot(google_reference_key)
    venue = Venue.where("google_place_reference = ?", google_reference_key).first
    if venue.blank?
      venue = Venue.new
      venue.google_place_reference = google_reference_key
    end
    venue.populate_google_address
    venue
  end

  def populate_google_address
    client = Venue.google_place_client
    spot = client.spot(self.google_place_reference)
    self.city = spot.city
    self.state = spot.region
    self.postal_code = spot.postal_code
    self.country = spot.country
    self.address = [ spot.street_number, spot.street].join(', ')
    self.save
  end

  def self.google_place_client
    GooglePlaces::Client.new(ENV['GOOGLE_PLACE_API_KEY'])
  end

  def v_up_votes
    LytitVote.where("venue_id = ? AND value = ?", self.id, 1).size
  end

  def v_down_votes
    LytitVote.where("venue_id = ? AND value = ?", self.id, -1).size
  end

  def t_minutes_since_last_up_vote
    minutes_since(1)
  end

  def t_minutes_since_last_down_vote
    minutes_since(-1)
  end

  def get_k
    if self.google_place_rating
      p = self.google_place_rating / 5
      return LytitBar::GOOGLE_PLACE_FACTOR * (p ** 2)
    end

    0
  end

  def bayesian_voting_average
    (LytitBar::BAYESIAN_AVERAGE_C * LytitBar::BAYESIAN_AVERAGE_M + (self.v_up_votes - self.v_down_votes)) / 
    (LytitBar::BAYESIAN_AVERAGE_M + (self.v_up_votes + self.v_down_votes))
  end

  private

  def minutes_since(vote)
    last_vote = LytitVote.where("venue_id = ? AND value = ?", self.id, vote).last

    last = last_vote.created_at
    now = Time.now.utc

    (now - last) / 1.minute
  end

end

#@client.spots(-33.8670522, 151.1957362, :radius => 100, :name => 'italian')
#@client.spots_by_query('italian', :radius => 1000, :lat => '-33.8670522', :lng => '151.1957362')