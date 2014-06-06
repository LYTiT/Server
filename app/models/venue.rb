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
    Venue.within(1.242, :origin => [latitude, longitude]).order('distance ASC').where("id IN (?)", list)
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
    LytitVote.where("venue_id = ? AND value = ?", self.id, 1)
  end

  def v_down_votes
    LytitVote.where("venue_id = ? AND value = ?", self.id, -1)
  end

  def t_minutes_since_last_up_vote
    minutes_since(1)
  end

  def t_minutes_since_last_down_vote
    minutes_since(-1)
  end

  def bayesian_voting_average
    up_votes_count = self.v_up_votes.size
    down_votes_count = self.v_down_votes.size

    (LytitBar::BAYESIAN_AVERAGE_C * LytitBar::BAYESIAN_AVERAGE_M + (up_votes_count - down_votes_count)) / 
    (LytitBar::BAYESIAN_AVERAGE_M + (up_votes_count + down_votes_count))
  end

  def account_new_vote(vote_value)
    if vote_value > 0
      account_up_vote
    else
      account_down_vote
    end

    #recalculate_rating
  end

  def recalculate_rating
    y = 1.0 / (1 + LytitBar::RATING_LOSS_L)

    a = self.r_up_votes || (1.0 + get_k)
    b = self.r_down_votes || 1.0

    puts "A = #{a}, B = #{b}, Y = #{y}"

    x = LytitBar::inv_inc_beta(a, b, y)
    
    puts "X = #{x}"

    self.rating = eval(x.to_s)
    save
  end

  private

  def minutes_since(vote)
    last_vote = LytitVote.where("venue_id = ? AND value = ?", self.id, vote).last

    last = last_vote.created_at
    now = Time.now.utc

    (now - last) / 1.minute
  end

  def account_up_vote
    self.r_up_votes = get_sum_of_past_votes(self.v_up_votes) + 1 + get_k
    save
  end

  def account_down_vote
    self.r_down_votes = get_sum_of_past_votes(self.v_down_votes) + 1
    save
  end

  def get_sum_of_past_votes(votes)
    now = Time.now.utc

    old_votes_sum = 0
    for vote in votes
      minutes_passed_since_vote = (now - vote.created_at) / 1.minute

      old_votes_sum += 2 ** ((- minutes_passed_since_vote) / LytitBar::VOTE_HALF_LIFE_H)
    end

    old_votes_sum
  end

  def get_k
    if self.google_place_rating
      p = self.google_place_rating / 5
      return LytitBar::GOOGLE_PLACE_FACTOR * (p ** 2)
    end

    0
  end

end

#@client.spots(-33.8670522, 151.1957362, :radius => 100, :name => 'italian')
#@client.spots_by_query('italian', :radius => 1000, :lat => '-33.8670522', :lng => '151.1957362')