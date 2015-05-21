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
  validates_numericality_of :outstanding_bounties, :greater_than_or_equal_to => 0

  has_many :venue_ratings, :dependent => :destroy
  has_many :venue_comments, :dependent => :destroy
  has_many :venue_messages, :dependent => :destroy
  has_many :menu_sections, :dependent => :destroy, :inverse_of => :venue
  has_many :menu_section_items, :through => :menu_sections

  has_many :lyt_spheres, :dependent => :destroy

  has_many :bounties, :dependent => :destroy

  has_many :instagram_location_ids, :dependent => :destroy

  belongs_to :user

  accepts_nested_attributes_for :venue_messages, allow_destroy: true, reject_if: proc { |attributes| attributes['message'].blank? or attributes['position'].blank? }

  MILE_RADIUS = 2

  has_many :lytit_votes, :dependent => :destroy

  scope :visible, -> { joins(:lytit_votes).where('lytit_votes.created_at > ?', Time.now - LytitConstants.threshold_to_venue_be_shown_on_map.minutes) }


  #determines the type of venue, ie, country, state, city, neighborhood, or just a regular establishment.
  def type
    v_address = address || ""
    v_city = city || ""
    v_state = state || ""
    v_country = country || ""

    if postal_code == nil or postal_code == ""
      vpostal_code = 0
    else
      vpostal_code = postal_code
    end

    if name == v_country && (v_address == "" && v_city == "") && (v_state == "" && vpostal_code.to_i == 0)
      type = 4 #country
    elsif (name.length == 2 && v_address == "") && (v_city == "" && vpostal_code.to_i == 0)
      type = 3 #state
    elsif ((name[0..(name.length-5)] == v_city && v_country == "United States") || (name == v_city && v_country != "United States")) && (v_address == "")
      type = 2 #city
    else
      type = 1 #establishment
    end

    return type
  end

  #bounty feed of a city, state, or country
  def self.area_bounty_feed(v_id)
    days_back = 1
    responded_to_bounty_ids = "SELECT id FROM bounties WHERE venue_id = #{v_id} AND (expiration >= NOW() OR (expiration < NOW() AND num_responses > 0)) AND (NOW() - created_at) <= INTERVAL '1 DAY'"
    feed = VenueComment.where("bounty_id IN (#{responded_to_bounty_ids}) AND user_id IS NULL", (Time.now - days_back.days)).includes(:venue, :bounty, bounty: :bounty_subscribers).order("updated_at desc")
  end

  #venues that are viewed often are "hot" and as a result reward users for posting if no posts present
  def is_hot?
    last_posted_comment_time_wrapper = self.latest_posted_comment_time || (Time.now - 31.minute)
    popularity_percentile_wrapper = self.popularity_percentile || 0.0
    if popularity_percentile_wrapper >= 75.0 && (Time.now - last_posted_comment_time_wrapper) >= 30.minutes
      true
    else
      false
    end
  end

  def bonus_lumens
    if self.is_hot? == true
      return 1
    else 
      return nil
    end
  end

  def view(user_id)
    view = VenuePageView.new(:user_id => user_id, :venue_id => self.id, :venue_lyt_sphere =>  self.l_sphere)
    view.save
  end


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

  def has_menue?
    if menue.menu_section_items.count = 0
      return false
    else
      return true
    end
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

  def self.venues_in_view(sw_lat, sw_long, ne_lat, ne_long)
    Venue.in_bounds([[sw_lat,sw_long],[ne_lat,ne_long]]).where("color_rating > -1.0 OR outstanding_bounties > 0").order("color_rating desc")
  end

  def self.fetch(vname, vaddress, vcity, vstate, vcountry, vpostal_code, vphone, vlatitude, vlongitude, pin_drop)
    if vname == nil && vcountry == nil
      return
    end

    #We need to determine the type of search being conducted whether it is venue specific or geographic
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
      radius = 75
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

      if ( (((venue.name).include? vname) || ((vname).include? venue.name)) && (specific_address == false) ) && (venue.address == vaddress) #Are they substrings?
        lookup = venue
        break
      end

      require 'fuzzystringmatch'
      jarow = FuzzyStringMatch::JaroWinkler.create( :native ) 
      if (p jarow.getDistance(venue.name, vname) >= 0.8) && (specific_address == false)
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
      if lookup.l_sphere == nil && vcity != nil #Add LYT Sphere if not present
        lookup.l_sphere = lookup.city.delete(" ")+(lookup.latitude.round(0).abs).to_s+(lookup.longitude.round(0).abs).to_s
        lookup.save
      end
      if lookup.time_zone == nil #Add timezone of venue if not present
        Timezone::Configure.begin do |c|
          c.username = 'LYTiT'
        end
        timezone = Timezone::Zone.new :latlon => [vlatitude, vlongitude]
        lookup.time_zone = timezone.active_support_time_zone
        lookup.save
      end
      if lookup.instagram_location_id == nil
        lookup.set_instagram_location_id
      end
      return lookup
    else
      Timezone::Configure.begin do |c|
        c.username = 'LYTiT'
      end
      timezone = Timezone::Zone.new :latlon => [vlatitude, vlongitude]

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
      if vcity != nil
        venue.l_sphere = venue.city.delete(" ")+(venue.latitude.round(0).abs).to_s+(venue.longitude.round(0).abs).to_s
      end
      venue.time_zone = timezone.active_support_time_zone
      venue.fetched_at = Time.now

      if vaddress != nil && vname != nil
        if vaddress.gsub(" ","").gsub(",", "") == vname.gsub(" ","").gsub(",", "")
          venue.is_address = true
        end
      end

      venue.save
      return venue
    end
  end

  #Bounding area in which to search for a venue as determined by target lat and long.
  def self.bounding_box(radius, lat, long)
    box = Hash.new()
    box["min_lat"] = lat.to_f - radius.to_i / (109.0 * 1000)
    box["max_lat"] = lat.to_f + radius.to_i / (109.0 * 1000)
    box["min_long"] = long.to_f - radius.to_i / (113.2 * 1000 * Math.cos(lat.to_f * Math::PI / 180))
    box["max_long"] = long.to_f + radius.to_i / (113.2 * 1000 * Math.cos(lat.to_f * Math::PI / 180))
    return box
  end

  def set_time_zone
    Timezone::Configure.begin do |c|
      c.username = 'LYTiT'
    end
    lat = 0/self.latitude == 0.0 ? self.latitude : 0.0
    long = 0/self.longitude == 0.0 ? self.longitude : 0.0
    timezone = Timezone::Zone.new :latlon => [lat, long] rescue nil
    self.time_zone = timezone.active_support_time_zone rescue nil
    self.save
  end

  #RUN THIS ON BOLT BEFORE RELEASE 1.0
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  def self.set_is_address_and_votes_received
    target_venues = Venue.all
    for v in target_venues
      if v.address != nil && v.name != nil
        if v.address.gsub(" ","").gsub(",", "") == v.name.gsub(" ","").gsub(",", "")
          v.update_columns(is_address: true)
        end
      end

      if v.lytit_votes.count > 0
        v.update_columns(has_been_voted_at: true)
      end
    end
  end

  def self.set_latest_placed_bounty_time
    v_ids = "SELECT venue_id FROM bounties WHERE user_id > 0"
    target_venues = Venue.where("id IN (#{v_ids})")
    for v in target_venues
      target_bounty = v.bounties.order("id desc").first
      v.update_columns(latest_placed_bounty_time: target_bounty.created_at)
    end
  end
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  #Uniform formatting of venues phone numbers into a "(XXX)-XXX-XXXX" style
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
      number = '(%s)-%s-%s' % [digits[0,3], digits[3,3], digits[6,4]]
    end
  end

  #temp method to reformat older telephones
  def reformatTelephone
    number = phone_number
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
      number = '(%s)-%s-%s' % [digits[0,3], digits[3,3], digits[6,4]]
    end
    update_columns(phone_number: number)
  end  


  def add_Geohash
    update_columns(geohash: GeoHash.encode(self.latitude, self.longitude))
  end

  def self.near_locations(lat, long)
    meter_radius = 400
    surroundings = Venue.within(Venue.meters_to_miles(meter_radius.to_i), :origin => [lat, long]).where("has_been_voted_at = TRUE AND is_address = FALSE").order('distance ASC limit 10')
  end

  def cord_to_city
    query = self.latitude.to_s + "," + self.longitude.to_s
    result = Geocoder.search(query).first 
     if (result)
      city = result.country
    end
    return city
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

  #priming factor that used to be calculted from historical average rating of a place
  def get_k
=begin    
    if self.google_place_rating
      p = self.google_place_rating / 5
      return (LytitConstants.google_place_factor * (p ** 2)).round(4)
    end
=end
    0
  end


#Instagram API locational content pulls
  def get_instagrams
    latest_instagram = self.latest_instagram_venue_comment
    if latest_instagram != nil
      instagrams = Instagram.location_recent_media(self.instagram_location_id, :min_timestamp => (Time.now-24.hours).to_time.to_i, :min_id => latest_instagram.instagram_id)
    else
      instagrams = Instagram.location_recent_media(self.instagram_location_id, :min_timestamp => (Time.now-24.hours).to_time.to_i)    
    end

    if instagrams != nil and instagrams.count > 0
      for posting in instagrams
        vc = VenueComment.new(:venue_id => self.id, :media_url => posting.images.standard_resolution.url, :media_type => "image", :content_origin => "instagram", :time_wrapper => DateTime.strptime("#{posting.created_time}",'%s'))
        vc.save
      end
    end
    self.update_columns(last_instagram_pull_time: Time.now)
  end

  def latest_instagram_venue_comment
    self.venue_comments.where("content_origin = ?", "instagram").order("time_wrapper desc").first
  end

  def set_instagram_location_id
    require 'fuzzystringmatch'
    jarow = FuzzyStringMatch::JaroWinkler.create( :native )    
    nearby_instagram_content = Instagram.media_search(latitude, longitude, :distance => 150, :count => 100)
    wide_area_search = false
    wide_area_hash = Hash.new

    if nearby_instagram_content.count == 0
      nearby_instagram_content = Instagram.media_search(latitude, longitude, :distance => 500, :count => 100)
    end

    if nearby_instagram_content.count == 0
      nearby_instagram_content = Instagram.media_search(latitude, longitude, :distance => 5000, :count => 100)
      wide_area_search = true
    end

    if nearby_instagram_content.count > 0
      for instagram in nearby_instagram_content
        if instagram.location.name != nil
          puts("#{instagram.location.name},   #{instagram.location.id}")
          if wide_area_search == false
            if instagram.location.name.downcase == self.name.downcase #Is there a direct string match?
              self.update_columns(instagram_location_id: instagram.location.id)
              break
            elsif ((instagram.location.name.downcase).include? self.name.downcase) || ((self.name.downcase).include? instagram.location.name.downcase)
              self.update_columns(instagram_location_id: instagram.location.id)
              break
            else
              if p jarow.getDistance(instagram.location.name.downcase, self.name.downcase ) >= 0.8 #Jaro Winkler String Algo comparison
                self.update_columns(instagram_location_id: instagram.location.id)
                break
              end
            end
          else #dealing with a wide area search so we select closest Jaro winkler comparison
            jw_distance = p jarow.getDistance(instagram.location.name.downcase, self.name.downcase ) 
            wide_area_hash[jw_distance] = instagram.location.id
          end
        end
      end

      if wide_area_search == true
        best_location_match_id = wide_area_hash.max_by{|k,v| k}.last
        self.update_columns(instagram_location_id: best_location_match_id)
      end

      if instagram_location_id != nil
        latest_location_postings = Instagram.location_recent_media(self.instagram_location_id, :min_timestamp => (Time.now-24.hours).to_time.to_i)

        if latest_location_postings.count >0  
          for posting in latest_location_postings
            vc = VenueComment.new(:venue_id => self.id, :media_url => posting.images.standard_resolution.url, :media_type => "image", :content_origin => "instagram", :time_wrapper => DateTime.strptime("#{posting.created_time}",'%s'), :instagram_id => posting.id)
            vc.save
          end
          self.update_columns(last_instagram_pull_time: Time.now)
        end
        i_l_i_t = InstagramLocationIdTracker.new(:venue_id => self.id, primary_instagram_location_id: self.instagram_location_id)
        i_l_i_t.save
      else
        self.update_columns(instagram_location_id: -1)
      end    
    end

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
    update_columns(r_up_votes: (get_sum_of_past_votes(up_votes, last.try(:time_wrapper), false) + 2.0 + get_k).round(4))

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
    update_columns(r_down_votes: (get_sum_of_past_votes(down_votes, last.try(:time_wrapper), true) + 2.0).round(4))

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
      minutes_passed_since_vote = (timestamp_last_vote - vote.time_wrapper) / 1.minute

      if is_down_vote
        old_votes_sum += 2 ** ((- minutes_passed_since_vote) / (2 * LytitConstants.vote_half_life_h))
      else
        old_votes_sum += 2 ** ((- minutes_passed_since_vote) / LytitConstants.vote_half_life_h)
      end
    end

    old_votes_sum
  end

end
