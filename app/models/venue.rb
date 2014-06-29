class Venue < ActiveRecord::Base

  acts_as_mappable :default_units => :miles,
                     :default_formula => :sphere,
                     :distance_field_name => :distance,
                     :lat_column_name => :latitude,
                     :lng_column_name => :longitude

  validates :name, presence: true
  validates :latitude, presence: true
  validates :longitude, presence: true
  validate :validate_menu_link

  has_many :venue_ratings, :dependent => :destroy
  has_many :venue_comments, :dependent => :destroy
  has_many :venue_messages, :dependent => :destroy
  has_many :groups_venues, :dependent => :destroy
  has_many :groups, through: :groups_venues
  has_many :menu_sections, :dependent => :destroy, :inverse_of => :venue
  has_many :menu_section_items, :through => :menu_sections

  has_many :events, :dependent => :destroy

  belongs_to :user

  accepts_nested_attributes_for :venue_messages, allow_destroy: true, reject_if: proc { |attributes| attributes['message'].blank? or attributes['position'].blank? }
  
  MILE_RADIUS = 2

  GOOGLE_PLACE_TYPES = %w(airport amusement_park art_gallery bakery bar bowling_alley bus_station cafe campground casino city_hall courthouse department_store embassy establishment finance food gym hospital library movie_theater museum night_club park restaurant school shopping_mall spa stadium university street_address neighborhood locality)

  has_many :lytit_votes, :dependent => :destroy

  scope :visible, -> { joins(:lytit_votes).where('lytit_votes.created_at > ?', Time.now - 210.minutes) }

  def menu_link=(val)
    if val.present?
      unless (val.start_with?("http://") or val.start_with?("https://"))
        val = "http://#{val}"
      end
    else
      val = nil
    end
    write_attribute(:menu_link, val)
  end

  def to_param
    [id, name.parameterize].join("-")
  end

  def messages
    venue_messages
  end

  def visible_venue_comments
    venue_comments.select{|comment| comment.flagged_comments.count < 2}
  end

  def self.search(params)
    if params[:full_query] && params[:lat] && params[:lng]
      Venue.fetch_venues('rankby', '', params[:lat], params[:lng], nil, params[:timewalk_start_time], params[:timewalk_end_time])
    else
      venues = where("start_date IS NULL or (start_date <= ? and end_date >= ?)", Time.now, Time.now)
      radius = params[:radius] ? Venue.meters_to_miles(params[:radius].to_i) : MILE_RADIUS
      if params[:lat] && params[:lng]
        venues = venues.within(radius, :origin => [params[:lat], params[:lng]]).order('distance ASC')
      end
      if params[:timewalk_start_time].present? and params[:timewalk_end_time].present?
        return Venue.timewalk_ratings(venues, params[:timewalk_start_time], params[:timewalk_end_time])
      else
        return venues
      end
    end
  end

  def self.fetch_venues(fetch_type, q, latitude, longitude, meters = nil, timewalk_start_time = nil, timewalk_end_time = nil)
    if not meters.present? and q.present?
      meters = 50000 
    end
    meters ||= 2000
    list = []
    client = Venue.google_place_client
    
    begin
      if fetch_type == 'rankby'
        spots = client.spots(latitude, longitude, :rankby => 'distance', :types => GOOGLE_PLACE_TYPES)
      else
        if q.blank?
          spots = client.spots(latitude, longitude, :radius => meters, :types => GOOGLE_PLACE_TYPES)
        else
          spots = client.spots_by_query(q, :radius => meters, :lat => latitude, :lng => longitude, :types => GOOGLE_PLACE_TYPES)
        end
      end
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
    rescue HTTParty::ResponseError => e
      if fetch_type == 'rankby'
        list = Venue.select(:id).within(Venue.meters_to_miles(meters.to_i), :origin => [latitude, longitude]).collect(&:id)
      else
        if q.blank?
          list = Venue.select(:id).within(Venue.meters_to_miles(meters.to_i), :origin => [latitude, longitude]).collect(&:id)
        else
          list = Venue.select(:id).within(Venue.meters_to_miles(meters.to_i), :origin => [latitude, longitude]).where("name ILIKE ?", "%#{q}%").collect(&:id)
        end
      end
    end

    venues = nil
    if fetch_type == 'rankby'
      venues = Venue.within(Venue.meters_to_miles(meters.to_i), :origin => [latitude, longitude]).order('distance ASC').where("id IN (?)", list).where("start_date IS NULL or (start_date <= ? and end_date >= ?)", Time.now, Time.now)
    else
      if q.blank?
        rated_venue_ids = Venue.within(Venue.meters_to_miles(meters.to_i), :origin => [latitude, longitude]).collect(&:id)
        list = list + rated_venue_ids
        venues = Venue.visible.within(Venue.meters_to_miles(meters.to_i), :origin => [latitude, longitude]).order('distance ASC').where("venues.id IN (?)", list.uniq)
      else
        list = list + Event.select(:venue_id).where("name ILIKE ?", "%#{q}%").where("start_date <= ? and end_date >= ?", Time.now, Time.now).collect(&:venue_id)
        venues = Venue.within(Venue.meters_to_miles(meters.to_i), :origin => [latitude, longitude]).order('distance ASC').where("venues.id IN (?)", list.uniq)
      end
    end

    if timewalk_start_time.present? and timewalk_end_time.present?
      return Venue.timewalk_ratings(venues, timewalk_start_time, timewalk_end_time)
    else
      return venues
    end

  end

  def self.timewalk_ratings(venues, timewalk_start_time, timewalk_end_time)
    venue_ids = venues.collect(&:id)
    venues = venues.as_json
    timewalk_start_time = Time.parse(timewalk_start_time)
    timewalk_end_time = Time.parse(timewalk_end_time)
    slots = []
    current_slot = timewalk_start_time
    begin
      slots << current_slot
      current_slot = current_slot + 15.minutes
    end while current_slot <= timewalk_end_time 
    slots.each do |time_slot|
      start_time = (time_slot - (7.minutes + 5.seconds)).utc.to_time
      end_time = (time_slot + (7.minutes + 5.seconds)).utc.to_time
      color_ratings = VenueColorRating.where(:venue_id => venue_ids, :created_at => {:$gt => start_time, :$lt => end_time}).order("created_at DESC").all
      venue_color_ratings = {}
      color_ratings.each do |color_rating|
        unless venue_color_ratings[color_rating["venue_id"]].present?
          venue_color_ratings[color_rating["venue_id"]] = color_rating["color_rating"]
        end
      end
      venues.each do |venue|
        venue["timewalk_color_ratings"] ||= {}
        venue["timewalk_color_ratings"][time_slot] = venue_color_ratings[venue["id"]] || -1
      end
    end
    venues
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
      begin
        client = Venue.google_place_client
        spot = client.spot(self.google_place_reference)
        self.city = spot.city
        self.state = spot.region
        self.postal_code = spot.postal_code
        self.country = spot.country
        self.address = [ spot.street_number, spot.street].compact.join(', ')
        self.fetched_at = Time.now
        self.save
      rescue HTTParty::ResponseError => e
      end
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

  def v_up_votes
    LytitVote.where("venue_id = ? AND value = ? AND created_at >= ?", self.id, 1, Time.now.at_beginning_of_day + 6.hours)
  end

  def v_down_votes
    LytitVote.where("venue_id = ? AND value = ? AND created_at >= ?", self.id, -1, Time.now.at_beginning_of_day + 6.hours)
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

    #Thread.new do
      recalculate_rating
    #end
  end

  def recalculate_rating
    y = 1.0 / (1 + LytitBar::RATING_LOSS_L)

    a = self.r_up_votes || (1.0 + get_k)
    b = self.r_down_votes || 1.0

    puts "A = #{a}, B = #{b}, Y = #{y}"

    #x = LytitBar::inv_inc_beta(a, b, y)
    # for some reason the python interpreter installed is not recognized by RubyPython
    x = `python2 -c "import scipy.special;print scipy.special.betaincinv(#{a}, #{b}, #{y})"`

    if $?.to_i == 0
      puts "X = #{x}"

      self.rating = eval(x)
      save
    else
      puts "Could not calculate rating. Status: #{$?.to_i}"
    end
  end

  def is_visible?
    if not self.rating
      return false
    end

    if minutes_since_last_vote >= LytitBar::THRESHOLD_TO_BE_SHOWN_ON_MAP
      return false
    end

    true
  end

  def reset_r_vector
    self.r_up_votes = 1 + get_k
    self.r_down_votes = 1
    save
  end

  def get_k
    if self.google_place_rating
      p = self.google_place_rating / 5
      return LytitBar::GOOGLE_PLACE_FACTOR * (p ** 2)
    end

    0
  end

  private

  def self.with_color_ratings(venues)
    ret = []

    diff_ratings = Set.new
    for venue in venues
      if venue.rating
        rat = venue.rating.round(2)
        diff_ratings.add(rat)
      end
    end

    diff_ratings = diff_ratings.to_a.sort

    step = 1.0 / (diff_ratings.size - 1)

    colors_map = {0.0 => 0.0} # null ratings will be out of the distribution range, just zero
    color = -step
    for rating in diff_ratings
      color += step
      colors_map[rating] = color.round(2)
    end

    for venue in venues
      rating = venue.rating ? venue.rating.round(2) : 0.0
      ret.append(venue.as_json.merge({'color_rating' => venue.is_visible? ? colors_map[rating] : -1}))
    end

    ret
  end

  def validate_menu_link
    if menu_link.present?
      begin
        uri = URI.parse(menu_link)
        raise URI::InvalidURIError unless uri.kind_of?(URI::HTTP)
        response = Net::HTTP.get_response(uri)
      rescue URI::InvalidURIError
        errors.add(:menu_link, "is not a valid URL.")
      rescue
        errors.add(:menu_link, "is not reachable. Please check the URL and try again.")
      end
    end
  end

  def minutes_since_last_vote
    last_vote = LytitVote.where("venue_id = ?", self.id).last

    if last_vote
      last = last_vote.created_at
      now = Time.now.utc

      (now - last) / 1.minute
    else
      LytitBar::THRESHOLD_TO_BE_SHOWN_ON_MAP
    end
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

end

#@client.spots(-33.8670522, 151.1957362, :radius => 100, :name => 'italian')
#@client.spots_by_query('italian', :radius => 1000, :lat => '-33.8670522', :lng => '151.1957362')