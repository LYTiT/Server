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

  has_many :rvenue_relationships, foreign_key: "vfollowed_id", class_name: "VenueRelationship",  dependent: :destroy
  has_many :followers, through: :rvenue_relationships, source: :ufollower


  has_many :events, :dependent => :destroy

  belongs_to :user

  accepts_nested_attributes_for :venue_messages, allow_destroy: true, reject_if: proc { |attributes| attributes['message'].blank? or attributes['position'].blank? }

  MILE_RADIUS = 2

  GOOGLE_PLACE_TYPES = %w(airport amusement_park art_gallery bakery bar bowling_alley bus_station cafe campground casino city_hall courthouse department_store embassy establishment finance food gym hospital library movie_theater museum night_club park restaurant school shopping_mall spa stadium university street_address neighborhood locality)

  GOOGLE_PLACE_VOTING_TYPES = %w(airport amusement_park art_gallery bakery bar bowling_alley bus_station cafe campground casino city_hall courthouse department_store embassy finance food gym hospital library movie_theater museum night_club park restaurant school shopping_mall spa stadium university street_address neighborhood locality)

  has_many :lytit_votes, :dependent => :destroy

  scope :visible, -> { joins(:lytit_votes).where('lytit_votes.created_at > ?', Time.now - LytitConstants.threshold_to_venue_be_shown_on_map.minutes) }

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
    ids = FlaggedComment.select("count(*) as count, venue_comment_id").joins(:venue_comment).where(:venue_comments => {:venue_id => self.id}).group("flagged_comments.venue_comment_id").collect{|a| a.venue_comment_id if a.count >= 50}.uniq.compact
    unless ids.present?
      ids = [-1]
    end
    venue_comments.where("venue_comments.id NOT IN (?)", ids)
  end

=begin >>>SEARCHING 1.0<<<
  def self.fetch_venues(fetch_type, q, latitude, longitude, meters = nil, timewalk_start_time = nil, timewalk_end_time = nil, group_id = nil, user = nil)
    if not meters.present? and q.present?
      meters = 50000
    end
    meters ||= 50000
    list = []
    client = Venue.google_place_client
    if (timewalk_start_time.present? and timewalk_end_time.present?) or group_id.present?
      list = default_venues(fetch_type, meters, latitude, longitude, q, group_id)
    else
      begin
        if fetch_type == 'rankby'
          spots = client.spots(latitude, longitude, :rankby => 'distance', :types => GOOGLE_PLACE_VOTING_TYPES)
        else
          if q.blank?
            spots = client.spots(latitude, longitude, :radius => meters, :types => GOOGLE_PLACE_TYPES)
          else
            #spots = client.spots_by_query(q, :radius => meters, :lat => latitude, :lng => longitude, :types => GOOGLE_PLACE_TYPES)
             spots = client.predictions_by_input(q, :radius => meters, :lat => latitude, :lng => longitude, :types => GOOGLE_PLACE_TYPES)
          end
        end
        keys = spots.collect(&:place_id)
        venues = Venue.where(google_place_key: keys)
        spots.each do |spot|
          venue = venues.select{|venue| venue.google_place_key == spot.place_id}.first
          venue ||= Venue.new()
          venue.name = spot.name
          venue.google_place_key = spot.place_id
          venue.google_place_rating = spot.rating
          venue.google_place_reference = spot.reference
          venue.latitude = spot.lat
          venue.longitude = spot.lng
          venue.formatted_address = spot.formatted_address
          venue.city = spot.city
          venue.save
          list << venue.id if venue.persisted?
        end
      rescue
        list = default_venues(fetch_type, meters, latitude, longitude, q, group_id)
      end
    end

    if timewalk_start_time.present? and timewalk_end_time.present?
      start_time = Time.parse(timewalk_start_time).utc.to_time
      end_time = Time.parse(timewalk_end_time).utc.to_time
      list = VenueColorRating.fields(:venue_id).where(:venue_id => list, :created_at => {:$gt => start_time, :$lt => end_time}).all.collect(&:venue_id)
    end

    venues = nil
    if fetch_type == 'rankby'
      venues = Venue.within(Venue.meters_to_miles(meters.to_i), :origin => [latitude, longitude]).order('distance ASC').where("id IN (?)", list).where("start_date IS NULL or (start_date <= ? and end_date >= ?)", Time.now, Time.now)
      venues = venues.joins(:groups_venues).where(groups_venues: {group_id: group_id}) if group_id.present?
      venues = venues.limit(20)
    else
      if q.blank?
        # rated_venue_ids = Venue.within(Venue.meters_to_miles(meters.to_i), :origin => [latitude, longitude]).collect(&:id)
        # list = list + rated_venue_ids
        if timewalk_start_time.present? and timewalk_end_time.present?
          venues = Venue.within(Venue.meters_to_miles(meters.to_i), :origin => [latitude, longitude]).order('distance ASC')
          venues = venues.joins(:groups_venues).where(groups_venues: {group_id: group_id}) if group_id.present?
        else
          venues = Venue.visible.within(Venue.meters_to_miles(meters.to_i), :origin => [latitude, longitude]).order('distance ASC').where("venues.color_rating <> -1.0 and venues.color_rating IS NOT NULL")
          venues = venues.joins(:groups_venues).where(groups_venues: {group_id: group_id}) if group_id.present?
        end
      else
        list = list + Event.select(:venue_id).where("name ILIKE ?", "%#{q}%").where("start_date <= ? and end_date >= ?", Time.now, Time.now).collect(&:venue_id)
        venues = Venue.within(Venue.meters_to_miles(meters.to_i), :origin => [latitude, longitude]).order('distance ASC').where("venues.id IN (?)", list.uniq)
        venues = venues.joins(:groups_venues).where(groups_venues: {group_id: group_id}) if group_id.present?        
        venues = venues.sort{ |a,b| Levenshtein.distance(q, a.name) <=> Levenshtein.distance(q, b.name) }
      end
    end

    if timewalk_start_time.present? and timewalk_end_time.present?
      data = {
        :venues => Venue.timewalk_ratings(venues, timewalk_start_time, timewalk_end_time, q.present?),
        :checkins => Venue.checkins(timewalk_start_time, timewalk_end_time, user)
      }
      return data
    else
      return venues.uniq
    end

  end

  def self.default_venues(fetch_type, meters, latitude, longitude, q, group_id)
    list = []
    if fetch_type == 'rankby'
      list = Venue.select(:id).within(Venue.meters_to_miles(meters.to_i), :origin => [latitude, longitude])
      list = list.joins(:groups_venues).where(groups_venues: {group_id: group_id}) if group_id.present?
      list = list.limit(20).collect(&:id)
    else
      if q.blank?
        # list = Venue.select(:id).within(Venue.meters_to_miles(meters.to_i), :origin => [latitude, longitude]).limit(20).collect(&:id)
      else
        list = Venue.select(:id).within(Venue.meters_to_miles(meters.to_i), :origin => [latitude, longitude]).where("name ILIKE ?", "%#{q}%")
        list = list.joins(:groups_venues).where(groups_venues: {group_id: group_id}) if group_id.present?
        list = list.limit(20).collect(&:id)
      end
    end
    list
  end

  def self.checkins(timewalk_start_time, timewalk_end_time, user)
    timeslot = {}
    if user.present?
      timewalk_start_time = DateTime.parse(timewalk_start_time)
      timewalk_end_time = DateTime.parse(timewalk_end_time)
      slots = []
      current_slot = timewalk_start_time
      begin
        slots << current_slot
        current_slot = current_slot + 15.minutes
      end while current_slot <= timewalk_end_time
      slots.each do |time_slot|
        timeslot[time_slot.as_json] = LytitVote.select(:venue_id).where("user_id = ? AND created_at BETWEEN ? AND ?", user.id, (time_slot - 45.minutes), time_slot).last.try(:venue_id)
      end
    end
    timeslot
  end

  def self.timewalk_ratings(venues, timewalk_start_time, timewalk_end_time, allow_blank)
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
        if venue_color_ratings[venue["id"]].present?
          venue["timewalk_color_ratings"][time_slot.as_json] = venue_color_ratings[venue["id"]]
        end
        if allow_blank and not venue["timewalk_color_ratings"][time_slot.as_json].present?
          venue["timewalk_color_ratings"][time_slot.as_json] = -1
        end
      end
    end
    venues.collect{|a|
      if a["timewalk_color_ratings"].present?
        color_values = a["timewalk_color_ratings"].values.uniq.compact
        if color_values.size == 1 and color_values.first == -1
        else
          a
        end
      end
    }.compact
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
        self.phone_number = spot.formatted_phone_number
        self.fetched_at = Time.now
        self.save
      rescue
      end
    end
  end
=end

  #1 degree of latitude is ~110.54km while 1 degree of longitude is ~113.20*cos(latitude)km. This does not account for flattening at the earth's poles but in our 
  #case it is sufficiently accurate (Santa, dealt with it!)
  #lat_raidus is the horizontal distance corresponding to zoom level of the device's screen.
  def self.venues_in_view(radius, lat, long)
    min_lat = lat.to_f - ((radius.to_i) * (284.0 / 160.0)) / (109.0 * 1000)
    max_lat = lat.to_f + ((radius.to_i) * (284.0 / 160.0)) / (109.0 * 1000)
    min_long = long.to_f - radius.to_i / (113.2 * 1000 * Math.cos(lat.to_f * Math::PI / 180))
    max_long = long.to_f + radius.to_i / (113.2 * 1000 * Math.cos(lat.to_f * Math::PI / 180))
    venues = Venue.where("latitude > ? AND latitude < ? AND longitude > ? AND longitude < ? AND color_rating > -1.0", min_lat, max_lat, min_long, max_long)
  end

  def self.newfetch(vname, vaddress, vcity, vstate, vcountry, vpostal_code, vphone, vlatitude, vlongitude, pin_drop)
    if vname == nil && vcountry == nil
      return
    end

    #Lookup up by unique key. Perhaps may have to resort to in the future.

    #lookup_key = createKey(vlatitude, vlongitude, vaddress)
    #venues = Venue.where("key = ?", lookup_key)
    # 3 is the allowed deviation allowed in lat and long in the 1/1000 place
    
    #lat_range = *( ( ((vlatitude.to_f)*1000).floor.abs - 3 )..( ((vlatitude.to_f)*1000).floor.abs + 3 ))
    #long_range = *( ( ((vlongitude.to_f)*1000).floor.abs - 3 )..( ((vlongitude.to_f)*1000).floor.abs + 3 ))
    #venues = Venue.where("CAST(LEFT(CAST(key AS VARCHAR), 5) AS INT) IN (?) AND CAST(RIGHT(CAST((key/1000) AS VARCHAR), 5) AS INT) IN (?)", lat_range, long_range)
    #--------------------------------

    #We need to determin the type of search being conducted whether it is venue specific or geographic
    if vaddress == nil
      if vcity != nil #city search
        radius = 3000
        boundries = bounding_box(radius, vlatitude, vlongitude)
        venues = Venue.where("latitude > ? AND latitude < ? AND longitude > ? AND longitude < ? AND 
          address IS NULL AND name = ? OR name = ?", boundries["min_lat"], boundries["max_lat"], boundries["min_long"], boundries["max_long"], vcity, vname)
        vpostal_code = 0 #We use the postal code as a flag for the client to realize that the returned POI is not a venue and so should not have a venue page
      end

      if vstate != nil && vcity == nil #state search
        radius = 30000
        boundries = bounding_box(radius, vlatitude, vlongitude)
        venues = Venue.where("latitude > ? AND latitude < ? AND longitude > ? AND longitude < ? AND 
          address IS NULL AND city IS NULL AND name = ? OR name = ?", boundries["min_lat"], boundries["max_lat"], boundries["min_long"], boundries["max_long"], vstate, vname)
        vpostal_code = 0 #We use the postal code as a flag for the client to realize that the returned POI is not a venue and so should not have a venue page
      end

      if (vcountry != nil && vstate == nil ) && vcity == nil #country search
        radius = 300000
        boundries = bounding_box(radius, vlatitude, vlongitude)
        venues = Venue.where("latitude > ? AND latitude < ? AND longitude > ? AND longitude < ? AND 
          address IS NULL AND city IS NULL AND state IS NULL AND name = ? OR name = ?", boundries["min_lat"], boundries["max_lat"], boundries["min_long"], boundries["max_long"], vcountry, vname)
        vpostal_code = 0 #We use the postal code as a flag for the client to realize that the returned POI is not a venue and so should not have a venue page
      end
    else #venue search 
      radius = 300
      boundries = bounding_box(radius, vlatitude, vlongitude)
      venues = Venue.where("latitude > ? AND latitude < ? AND longitude > ? AND longitude < ?", boundries["min_lat"], boundries["max_lat"], boundries["min_long"], boundries["max_long"])
    end

    lookup = nil 
    specific_address = false 

    #When a user searches for a specific address we should always take him/her to the venue page of that exact address; however
    #when a pin is dropped, because a specific address is not established by the user
    if ( vname == vaddress ) && ( pin_drop == "0" )
      specific_address = true
    end

    #Iterate through venues in target area to find a string match by name
    for venue in venues
      if venue.name == vname #Is there a direct string match?
        lookup = venue
        break
      end

      if ( ((venue.name).include? vname) || ((vname).include? venue.name) ) && ( specific_address == false ) #Are they substrings?
        lookup = venue
        break
      end

      proximity = vname.length >= venue.name.length ? venue.name.length : vname.length
      if ( Levenshtein.distance(venue.name, vname) <= (proximity/2) ) && ( specific_address == false ) #Levenshtein distance as a last resort
        lookup = venue
      end
    end

    if lookup != nil
      lookup.postal_code = vpostal_code.to_s #We always set the postal code no matter what because we use it as a flag to determine if a venue page should be displayed
      lookup.save
      if lookup.city == nil || lookup.state == nil #Add venue details if they are not present
        lookup.address = vaddress
        
        part1 = [vaddress, vcity].compact.join(', ')
        part2 = [part1, vstate].compact.join(', ')
        part3 = [part2, vpostal_code].compact.join(' ')
        part4 = [part3, vcountry].compact.join(', ')

        lookup.formatted_address = part4
        lookup.city = vcity
        lookup.state = vstate
        lookup.country = vcountry
        lookup.phone_number = formatTelephone(vphone)
        lookup.save
      end
      return lookup
    else
      venue = Venue.new
      venue.name = vname
      venue.address = vaddress
      
      part1 = [vaddress, vcity].compact.join(', ')
      part2 = [part1, vstate].compact.join(', ')
      part3 = [part2, vpostal_code].compact.join(' ')
      part4 = [part3, vcountry].compact.join(', ')

      venue.formatted_address = part4
      venue.city = vcity
      venue.state = vstate
      venue.country = vcountry
      venue.postal_code = vpostal_code.to_s
      venue.phone_number = formatTelephone(vphone)
      venue.latitude = vlatitude
      venue.longitude = vlongitude
      #venue.key = createKey(vlatitude, vlongitude, vaddress)
      venue.fetched_at = Time.now
      venue.save
      return venue
    end
  end

  #LYTiT specific identifier keys for venues
=begin  def self.createKey(lat, long, addrs)
    part1 = ((lat.to_f)*1000).floor.abs.to_s
    part2 = ((long.to_f)*1000).floor.abs.to_s
    part3 = addrs.split(" ").first.to_s

    key = (part1+part2+part3).to_i
  end

  def createKeylocal(lat, long, addrs)
    part1 = ((lat.to_f)*1000).floor.abs.to_s
    part2 = ((long.to_f)*1000).floor.abs.to_s
    part3 = addrs.split(" ").first.to_s

    key = (part1+part2+part3).to_i
  end

  def addKey
    a1 = self.address
    a2 = self.formatted_address
    target = a1 || a2

    if target == nil 
      self.delete
    else
      key = createKeylocal(self.latitude, self.longitude, target)
      update_columns(key: key)
    end
  end
=end

  def self.bounding_box(radius, lat, long)
    box = Hash.new()
    box["min_lat"] = lat.to_f - radius.to_i / (109.0 * 1000)
    box["max_lat"] = lat.to_f + radius.to_i / (109.0 * 1000)
    box["min_long"] = long.to_f - radius.to_i / (113.2 * 1000 * Math.cos(lat.to_f * Math::PI / 180))
    box["max_long"] = long.to_f + radius.to_i / (113.2 * 1000 * Math.cos(lat.to_f * Math::PI / 180))
    return box
  end

  #Uniform formatting of venues phone numbers into a "+X (XXX) XXX-XXXX" style
  def self.formatTelephone(number)
    if number == nil
      return
    end

    digits = number.gsub(/\D/, '').split(//)
    lead = digits[0]

    if (digits.length == 11)
      digits.shift
    end

    digits = digits.join
    if (digits.length == 10)
      number = '+%s (%s) %s-%s' % [lead, digits[0,3], digits[3,3], digits[6,4] ]
    end
  end

  def add_Geohash
    update_columns(geohash: GeoHash.encode(self.latitude, self.longitude))
  end

  def self.near_locations(lat, long)
=begin    
    boundry = GeoHash.neighbors(self.geohash)
    adj_boundry = []
    boundry.each {|bound| adj_boundry << bound[0,7]}
    adj_boundry
    #neighbors = "SELECT venue FROM venues WHERE LEFT(geohash,7) IN (#{boundry})"
    neighbors = Venue.where("LEFT(geohash, 7) IN (?)", adj_boundry)
    neighbors = neighbors.order('distance ASC')
=end
    meter_radius = 400
    surroundings = Venue.within(Venue.meters_to_miles(meter_radius.to_i), :origin => [lat, long]).order('distance ASC')
    suggestions = []
    count = 0

    #Must ommit custom locations (addresses) from being pulled into the surrounding venues display that is the reason for the second part of the if block
    for location in surroundings
      if (LytitVote.where("venue_id = ?", location.id).count > 0 && location.city != nil) && (location.address.gsub(" ","").gsub(",", "") != location.name.gsub(" ","").gsub(",", "")) 
        suggestions << location
        count += 1
        if count == 10
          break
        end
      end
    end 
    return suggestions.compact
  end

  def self.recommended_venues(user, lat, long)
    meter_radius = 1000
    surroundings = Venue.within(Venue.meters_to_miles(meter_radius.to_i), :origin => [lat, long]).order('distance ASC')
    recommendations = []
    count = 0

    for location in surroundings
      if VenueComment.where("venue_id = ? AND NOT media_type = ?", location.id, "text").count > 1 && user.vfollowing?(location) == false
        recommendations << location
        count += 1
        if count == 10
          break
        end
      end
    end
    return recommendations.compact
  end

  def last_image_url
    images = VenueComment.where("venue_id = ? AND media_type = ?", self.id, "image")
    images = images.sort_by{|x,y| x.created_at}.reverse
    if images.first != nil
      return images.first.media_url
    end
  end

  def cord_to_city
    query = self.latitude.to_s + "," + self.longitude.to_s
    result = Geocoder.search(query).first 
     if (result)
      city = result.country
    end
    return city
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
    LytitVote.where("venue_id = ? AND value = ? AND created_at >= ?", self.id, 1, valid_votes_timestamp)
  end

  def v_down_votes
    LytitVote.where("venue_id = ? AND value = ? AND created_at >= ?", self.id, -1, valid_votes_timestamp)
  end

  def bayesian_voting_average
    up_votes_count = self.v_up_votes.size
    down_votes_count = self.v_down_votes.size

    (LytitConstants.bayesian_average_c * LytitConstants.bayesian_average_m + (up_votes_count - down_votes_count)) /
    (LytitConstants.bayesian_average_m + (up_votes_count + down_votes_count))
  end

  def account_new_vote(vote_value, vote_id)
    puts "bar position = #{LytitBar.instance.position}"
    if vote_value > 0
      puts "up vote, accounting"
      account_up_vote
    else
      puts "down vote, accounting"
      account_down_vote
    end

    recalculate_rating(vote_id)
  end

  def recalculate_rating(vote_id)
    y = (1.0 / (1 + LytitConstants.rating_loss_l)).round(4)

    a = self.r_up_votes || (1.0 + get_k)
    b = self.r_down_votes || 1.0

    puts "A = #{a}, B = #{b}, Y = #{y}"

    #x = LytitBar::inv_inc_beta(a, b, y)
    # for some reason the python interpreter installed is not recognized by RubyPython
    x = `python2 -c "import scipy.special;print scipy.special.betaincinv(#{a}, #{b}, #{y})"`

    if $?.to_i == 0
      puts "rating before = #{self.rating}"
      puts "rating after = #{x}"

      new_rating = eval(x).round(4)

      self.rating = new_rating

      vote = LytitVote.find(vote_id)
      vote.update_columns(rating_after: new_rating)
      save
    else
      puts "Could not calculate rating. Status: #{$?.to_i}"
    end
  end

  def update_rating()
    up_votes = self.v_up_votes.order('id ASC').to_a
    update_columns(r_up_votes: (get_sum_of_past_votes(up_votes, nil, false) + 1.0 + get_k).round(4))

    down_votes = self.v_down_votes.order('id ASC').to_a
    update_columns(r_down_votes: (get_sum_of_past_votes(down_votes, nil, true) + 1.0).round(4))

    y = (1.0 / (1 + LytitConstants.rating_loss_l)).round(4)

    r_up_votes = self.r_up_votes
    r_down_votes = self.r_down_votes

    a = r_up_votes >= 1 ? r_up_votes : (1.0 + get_k)
    b = r_down_votes >= 1 ? r_down_votes : 1.0

    if (a - 1.0 - get_k).round(4) == 0.0 and (b - 1.0).round(4) == 0.0
      update_columns(rating: 0.0)
    else
      puts "A = #{a}, B = #{b}, Y = #{y}"

      # x = LytitBar::inv_inc_beta(a, b, y)
      # for some reason the python interpreter installed is not recognized by RubyPython
      x = `python2 -c "import scipy.special;print scipy.special.betaincinv(#{a}, #{b}, #{y})"`

      if $?.to_i == 0
        puts "rating before = #{self.rating}"
        puts "rating after = #{x}"

        new_rating = eval(x).round(4)

        update_columns(rating: new_rating)
      else
        puts "Could not calculate rating. Status: #{$?.to_i}"
      end
    end
  end

  def is_visible?
    if not self.rating || self.rating == 0.0
      return false
    end

    if minutes_since_last_vote >= LytitConstants.threshold_to_venue_be_shown_on_map
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
      return (LytitConstants.google_place_factor * (p ** 2)).round(4)
    end

    0
  end

  private ##################################################################################################

  def valid_votes_timestamp
    now = Time.now
    now.hour >= 6 ? now.at_beginning_of_day + 6.hours : now.yesterday.at_beginning_of_day + 6.hours
  end

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
      LytitConstants.threshold_to_venue_be_shown_on_map
    end
  end

  def account_up_vote
    up_votes = self.v_up_votes.order('id ASC').to_a
    last = up_votes.pop # current vote should not be considered for the sum of the past

    # we sum 2 instead of 1 because the initial value of the R-vector is (1 + K, 1)
    # refer to the algo spec document
    update_columns(r_up_votes: (get_sum_of_past_votes(up_votes, last.try(:created_at), false) + 2.0 + get_k).round(4))

    #making sure down votes component is initialized (is set by default though to 1.0)
    if self.r_down_votes < 1.0
      update_columns(r_down_votes: 1.0)
    end
  end

  def account_down_vote
    down_votes = self.v_down_votes.order('id ASC').to_a
    last = down_votes.pop # current vote should not be considered for the sum of the past

    # we sum 2 instead of 1 because the initial value of the R-vector is (1 + K, 1)
    # refer to the algo spec document
    update_columns(r_down_votes: (get_sum_of_past_votes(down_votes, last.try(:created_at), true) + 2.0).round(4))

    #if first vote is a down vote up votes must be primed
    if self.r_up_votes <= 1.0 && get_k > 0
      update_columns(r_up_votes: (1.0 + get_k))
    end
  end

  # we need the timestamp of the last vote, since the accounting of votes
  # is executed in parallel (new thread) and probably NOT right after the
  # push of the current vote through the API
  #
  # Time.now could be used if we have guaranteed that the accounting of
  # the vote will be done right away, which is not the case with the use of
  # delayed jobs
  def get_sum_of_past_votes(votes, timestamp_last_vote, is_down_vote)
    if not timestamp_last_vote
      timestamp_last_vote = Time.now.utc
    end

    old_votes_sum = 0
    for vote in votes
      minutes_passed_since_vote = (timestamp_last_vote - vote.created_at) / 1.minute

      if is_down_vote
        old_votes_sum += 2 ** ((- minutes_passed_since_vote) / (2 * LytitConstants.vote_half_life_h))
      else
        old_votes_sum += 2 ** ((- minutes_passed_since_vote) / LytitConstants.vote_half_life_h)
      end
    end

    old_votes_sum
  end

end

#@client.spots(-33.8670522, 151.1957362, :radius => 100, :name => 'italian')
#@client.spots_by_query('italian', :radius => 1000, :lat => '-33.8670522', :lng => '151.1957362')
