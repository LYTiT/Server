class Venue < ActiveRecord::Base
  include PgSearch  

  pg_search_scope :name_search, #name and/or associated meta data
    :against => [:ts_name_vector, :metaphone_name_vector],
    :using => {
      :tsearch => {
        :normalization => 2,
        :dictionary => 'english',
        :any_word => true,
        :prefix => true,
        :tsvector_column => 'ts_name_vector',
      },
      :dmetaphone => {
        :tsvector_column => "metaphone_name_vector",
        :prefix => true,
      }  
    },
    :ranked_by => "(((:dmetaphone) + (:trigram))*(:tsearch) + (:trigram))"    


  pg_search_scope :phonetic_search,
              :against => "metaphone_name_vector",
              :using => {
                :dmetaphone => {
                  :tsvector_column => "metaphone_name_vector",
                  :prefix => true
                }  
              },
              :ranked_by => ":dmetaphone + (0.25 * :trigram)"#":trigram"#

  pg_search_scope :meta_search, #name and/or associated meta data
    against: :meta_data_vector,
    using: {
      tsearch: {
        dictionary: 'english',
        any_word: true,
        prefix: true,
        tsvector_column: 'meta_data_vector'
      }
    }                

  pg_search_scope :fuzzy_name_search, lambda{ |target_name, rigor|
    raise ArgumentError unless rigor <= 1.0
    {
      :against => :name,
      :query => target_name,
      :using => {
        :trigram => {
          :threshold => rigor #higher value corresponds to stricter comparison
        }
      }
    }
  }
                
                          
#---------------------------------------------------------------------------------------->

  acts_as_mappable :default_units => :kms,
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
  has_many :tweets, :dependent => :destroy
  has_many :venue_messages, :dependent => :destroy
  has_many :menu_sections, :dependent => :destroy, :inverse_of => :venue
  has_many :menu_section_items, :through => :menu_sections
  has_many :lyt_spheres, :dependent => :destroy
  has_many :lytit_votes, :dependent => :destroy
  has_many :meta_datas, :dependent => :destroy
  has_many :instagram_location_id_lookups, :dependent => :destroy
  has_many :feed_venues
  has_many :feeds, through: :feed_venues
  has_many :activities, :dependent => :destroy
  has_many :activities, :dependent => :destroy
  has_many :events, :dependent => :destroy

  has_many :venue_questions, :dependent => :destroy
  has_many :live_users

  belongs_to :user

  accepts_nested_attributes_for :venue_messages, allow_destroy: true, reject_if: proc { |attributes| attributes['message'].blank? or attributes['position'].blank? }

  MILE_RADIUS = 2

  scope :close_to, -> (latitude, longitude, distance_in_meters = 2000) {
    where(%{
      ST_DWithin(
        ST_GeographyFromText(
          'SRID=4326;POINT(' || venues.longitude || ' ' || venues.latitude || ')'
        ),
        ST_GeographyFromText('SRID=4326;POINT(%f %f)'),
        %d
      )
    } % [longitude, latitude, distance_in_meters])
  }

  scope :far_from, -> (latitude, longitude, distance_in_meters = 2000) {
    where(%{
      NOT ST_DWithin(
        ST_GeographyFromText(
          'SRID=4326;POINT(' || venues.longitude || ' ' || venues.latitude || ')'
        ),
        ST_GeographyFromText('SRID=4326;POINT(%f %f)'),
        %d
      )
    } % [longitude, latitude, distance_in_meters])
  }

  scope :inside_box, -> (sw_longitude, sw_latitude, ne_longitude, ne_latitude) {
    where(%{
        ST_GeographyFromText('SRID=4326;POINT(' || venues.longitude || ' ' || venues.latitude || ')') @ ST_MakeEnvelope(%f, %f, %f, %f, 4326) 
        } % [sw_longitude, sw_latitude, ne_longitude, ne_latitude])
  }
=begin
    where(%{
      ST_Intersects(
        ST_MakeEnvelope(%f, %f, %f, %f, 4326), ST_GeographyFromText('SRID=4326;POINT(' || venues.longitude || ' ' || venues.latitude || ')') 
        )} % [sw_longitude, sw_latitude, ne_longitude, ne_latitude])
  }


=begin    
    where(%{ST_GeographyFromText(
          'SRID=4326;POINT(' || venues.longitude || ' ' || venues.latitude || ')'
        ) 
      && ST_MakeEnvelope(%f, %f, %f, %f, 4326), 2223)
    } % [sw_longitude, sw_latitude, ne_longitude, ne_latitude])
  }
=end



  scope :visible, -> { joins(:lytit_votes).where('lytit_votes.created_at > ?', Time.now - LytitConstants.threshold_to_venue_be_shown_on_map.minutes) }


  #I. Search------------------------------------------------------->
  def Venue.search(query, proximity_box, view_box)
    first_letter = query.first
    second_letter = query[1]
    #perculate results with matching first letters to front.
    if proximity_box == nil
      raw_results = Venue.name_search(query).with_pg_search_rank.limit(50).sort_by { |venue| [venue.name.first, -venue.pg_search_rank]}
    elsif view_box != nil
      raw_results = Venue.where("latitude > ? AND latitude < ? AND longitude > ? AND longitude < ?", 
        view_box[:sw_lat], view_box[:ne_lat], view_box[:sw_long], view_box[:ne_long]).name_search(query).with_pg_search_rank.limit(50).sort_by { |venue| [venue.name.first, -venue.pg_search_rank]}
    else
      raw_results = Venue.in_bounds(proximity_box).name_search(query).with_pg_search_rank.limit(50).sort_by { |venue| [venue.name.first, -venue.pg_search_rank]}
    end

    first_letter_match_offset = raw_results.find_index{|venue| venue.name.size > 0 and (venue.name[0].downcase == first_letter.downcase)}
    if first_letter_match_offset != nil
      first_letter_sorted_results = raw_results.rotate(first_letter_match_offset)
    else
      first_letter_sorted_results = []
    end
    
    if first_letter_sorted_results != [] && query.length >= 2
      second_letter_match_offset = first_letter_sorted_results.find_index{|venue| venue.name.size > 0 and (venue.name[1].downcase == second_letter.downcase)}
      if second_letter_match_offset != nil
        second_letter_sorted_results = first_letter_sorted_results.rotate(second_letter_match_offset).first(10)
        results = second_letter_sorted_results
      else
        results = first_letter_sorted_results.first(10)
      end
    else
      results = []
    end

    if results != [] and results.first.pg_search_rank >= 0.1
      results
    else
      []
    end

  end

  def self.direct_fetch(query, position_lat, position_long, ne_lat, ne_long, sw_lat, sw_long)
    if query.first =="/"  
      query[0] = ""
      meta_results = Venue.where("latitude > ? AND latitude < ? AND longitude > ? AND longitude < ?", sw_lat, ne_lat, sw_long, ne_long).meta_search(query).limit(20).order("updated_at DESC")
    else
      first_letter = query.first
      if (ne_lat.to_f != 0.0 && ne_long.to_f != 0.0) and (sw_lat.to_f != 0.0 && sw_long.to_f != 0.0)
        central_screen_point = [(ne_lat.to_f-sw_lat.to_f), (ne_long.to_f-sw_long.to_f)]
        if Geocoder::Calculations.distance_between(central_screen_point, [position_lat, position_long], :units => :km) <= 10 and Geocoder::Calculations.distance_between(central_screen_point, [ne_lat, ne_long], :units => :km) <= 100
            
            search_box = Geokit::Bounds.from_point_and_radius(center_point, 20, :units => :kms)
            Venue.search(query, search_box, nil)
            #proximity_results = Venue.in_bounds(search_box).search(query).limit(50)
            #sorted_proximity_results = (proximity_results.rotate(offset) if offset = proximity_results.find_index{|venue| venue.name.size > 0 and venue.name[0].downcase == first_letter.downcase})[0..9] rescue nil
        else
            outer_region = {:ne_lat => ne_lat, :ne_long => ne_long,:sw_lat => sw_lat ,:sw_long => sw_long}
            Venue.search(query, nil, outer_region)

            #distant_results = Venue.where("latitude > ? AND latitude < ? AND longitude > ? AND longitude < ?", sw_lat, ne_lat, sw_long, ne_long).search(query).limit(50)
            #in_view_results = (distant_results.rotate(offset) if offset = distant_results.find_index{|venue| venue.name.size > 0 and venue.name[0].downcase == first_letter.downcase})[0..9] rescue nil
            #Venue.where("latitude > ? AND latitude < ? AND longitude > ? AND longitude < ?", sw_lat, ne_lat, sw_long, ne_long).search(query).limit(10)
        end
      else
        Venue.search(query, nil, nil)
        #sorted_results = (raw_results.rotate(offset) if offset = raw_results.find_index{|venue| venue.name.size > 0 and venue.name[0].downcase == first_letter.downcase})[0..9] rescue nil
      end
    end
  end

  #Venue.search(query).limit(50).rotate(offset) if offset = Venue.search(query).limit(50).find_index{|b| b.name.size > 0 and b.name[0] == query.first}

  def self.fetch(vname, vaddress, vcity, vstate, vcountry, vpostal_code, vphone, vlatitude, vlongitude)
    lat_long_lookup = Venue.where("latitude = ? AND longitude = ?", vlatitude, vlongitude).fuzzy_name_search(vname, 0.8).first    
    
    if lat_long_lookup == nil
      center_point = [vlatitude, vlongitude]
      search_box = Geokit::Bounds.from_point_and_radius(center_point, 0.250, :units => :kms)
      result = Venue.search(vname, search_box, nil).first
      if result == nil
        if vaddress == nil
          if vcity != nil #city search
            search_box = Geokit::Bounds.from_point_and_radius(center_point, 10, :units => :kms)
            result = Venue.in_bounds(search_box).where("address IS NULL AND name = ? OR name = ?", vcity, vname).first
          end

          if vstate != nil && vcity == nil #state search
            search_box = Geokit::Bounds.from_point_and_radius(center_point, 100, :units => :kms)
            result = Venue.in_bounds(search_box).where("address IS NULL AND city IS NULL AND name = ? OR name = ?", vstate, vname).first
          end

          if (vcountry != nil && vstate == nil ) && vcity == nil #country search
            search_box = Geokit::Bounds.from_point_and_radius(center_point, 1000, :units => :kms)
            result = Venue.in_bounds(search_box).where("address IS NULL AND city IS NULL AND state IS NULL AND name = ? OR name = ?", vcountry, vname).first
          end
        else #venue search
          search_box = Geokit::Bounds.from_point_and_radius(center_point, 0.250, :units => :kms)
          result = Venue.in_bounds(search_box).fuzzy_name_search(vname, 0.8).first
        end
      end
    else
      result = lat_long_lookup
    end

    if result == nil
      if vlatitude != nil && vlongitude != nil 
        result = Venue.create_new_db_entry(vname, vaddress, vcity, vstate, vcountry, vpostal_code, vphone, vlatitude, vlongitude, nil, nil)
        result.update_columns(verified: true)
      else
        return nil
      end
    end

    result.delay.calibrate_attributes(vname, vaddress, vcity, vstate, vcountry, vpostal_code, vphone, vlatitude, vlongitude)

    return result 
  end

  def self.fetch_venues_for_instagram_pull(vname, lat, long, inst_loc_id, vortex)
    #Reference LYTiT Instagram Location Id Database
    inst_id_lookup = InstagramLocationIdLookup.find_by_instagram_location_id(inst_loc_id)

    vname = scrub_venue_name(vname, vortex)
    if vname != nil
      if inst_id_lookup != nil && inst_loc_id.to_i != 0
        result = inst_id_lookup.venue
      else
        #Check if there is a direct name match in proximity
        center_point = [lat, long]
        search_box = Geokit::Bounds.from_point_and_radius(center_point, 0.3, :units => :kms)

        name_lookup = Venue.in_bounds(search_box).fuzzy_name_search(vname, 0.7).first
        if name_lookup == nil
          name_lookup = Venue.search(vname, search_box, nil).first
        end

        if name_lookup != nil
          result = name_lookup
        else
          result = nil
        end
      end
      return result
    else
      return nil
    end
  end

  def self.scrub_venue_name(raw_name, origin_vortex)
    #Many Instagram names are contaminated with extra information inputted by the user, i.e "Concert @ Madison Square Garden"
    clean_name = raw_name

    if raw_name.include?("@") == true
      clean_name = raw_name.partition("@").last.strip
    end

    if clean_name.include?("#{origin_vortex.city}") == true
      clean_name = clean_name.partition("#{origin_vortex.city}").first.strip
    end

    return clean_name 
  end

  def self.create_new_db_entry(name, address, city, state, country, postal_code, phone, latitude, longitude, instagram_location_id, origin_vortex)
    venue = Venue.create!(:name => name, :latitude => latitude, :longitude => longitude, :fetched_at => Time.now)
    
    if city == nil
      closest_venue = Venue.within(10, :units => :kms, :origin => [latitude, longitude]).order("distance ASC").first
      if closest_venue != nil
        city = closest_venue.city
        country = closest_venue.country
      else
        if origin_vortex != nil
          city = origin_vortex.city
          country = origin_vortex.country
        else
          city = nil
          country = nil
        end  
      end
    end

    #city = city.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n,'').to_s rescue nil#Removing accent marks

    venue.update_columns(address: address) 

    formatted_address = "#{address}, #{city}, #{state} #{postal_code}, #{country}"

    part1 = [address, city].compact.join(', ')
    part2 = [part1, state].compact.join(', ')
    part3 = [part2, postal_code].compact.join(' ')
    part4 = [part3, country].compact.join(', ')

    venue.update_columns(formatted_address: part4) 
    venue.update_columns(city: city) 
    venue.update_columns(state: state) 
    venue.update_columns(country: country)

    if postal_code != nil
      venue.postal_code = postal_code.to_s
    end
    
    if phone != nil
      venue.phone_number = Venue.formatTelephone(phone)
    end

    if venue.latitude < 0 && venue.longitude >= 0
      quadrant = "a"
    elsif venue.latitude < 0 && venue.longitude < 0
      quadrant = "b"
    elsif venue.latitude >= 0 && venue.longitude < 0
      quadrant = "c"
    else
      quadrant = "d"
    end
    venue.l_sphere = quadrant+(venue.latitude.round(1).abs).to_s+(venue.longitude.round(1).abs).to_s
    venue.save

    if address != nil && name != nil
      if address.gsub(" ","").gsub(",", "") == name.gsub(" ","").gsub(",", "")
        venue.is_address = true
      end
    end

    if instagram_location_id != nil
      venue.update_columns(instagram_location_id: instagram_location_id)  
    end

    venue.save

    if origin_vortex != nil
      venue.update_columns(instagram_vortex_id: origin_vortex.id)      
    end    
    venue.delay.set_time_zone_and_offset(origin_vortex)

    return venue    
  end

  def set_time_zone_and_offset(origin_vortex)
    if origin_vortex == nil
      Timezone::Configure.begin do |c|
      c.username = 'LYTiT'
      end
      timezone = Timezone::Zone.new :latlon => [self.latitude, self.longitude] rescue nil

      self.time_zone = timezone.active_support_time_zone rescue nil
      self.time_zone_offset = Time.now.in_time_zone(timezone.active_support_time_zone).utc_offset/3600.0 rescue nil
      self.save
    else
      self.update_columns(time_zone_offset: origin_vortex.time_zone_offset)
    end
  end

  def Venue.fill_in_time_zone_offsets
    radius  = 10000
    for venue in Venue.all.where("time_zone_offset IS NULL")
      closest_vortex = InstagramVortex.within(radius.to_i, :units => :kms, :origin => [venue.latitude, venue.longitude]).where("time_zone_offset IS NOT NULL").order('distance ASC').first
      venue.update_columns(time_zone_offset: closest_vortex.time_zone_offset)
    end
  end

  def calibrate_attributes(auth_name, auth_address, auth_city, auth_state, auth_country, auth_postal_code, auth_phone, auth_latitude, auth_longitude)
    #We calibrate with regards to the Apple Maps database
    auth_city = auth_city.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n,'').to_s rescue nil#Removing accent marks
    #Name
    if self.name != auth_name
      self.name = auth_name
    end

    #Address
    if (self.city == nil || self.state == nil) or (self.city != auth_city) #Add venue details if they are not present
      self.update_columns(formatted_address: Venue.address_formatter(address, city, state, postal_code, country))
      self.update_columns(city: auth_city)
      self.update_columns(state: auth_state)
      self.update_columns(country: auth_country) 

      if auth_phone != nil
        self.phone_number = Venue.formatTelephone(auth_phone)
      end
      self.save
    end

    #Geo
    if auth_latitude != nil and self.latitude != auth_latitude
      self.latitude = auth_latitude
    end

    if auth_longitude != nil and self.longitude != auth_longitude
      self.longitude = auth_longitude
    end      

    #LSphere
    if self.l_sphere == nil
      if self.latitude < 0 && self.longitude >= 0
        quadrant = "a"
      elsif self.latitude < 0 && self.longitude < 0
        quadrant = "b"
      elsif self.latitude >= 0 && self.longitude < 0
        quadrant = "c"
      else
        quadrant = "d"
      end
      self.l_sphere = quadrant+(self.latitude.round(1).abs).to_s+(self.longitude.round(1).abs).to_s
      self.save
    end

    #Timezones
    if self.time_zone == nil #Add timezone of venue if not present
      Timezone::Configure.begin do |c|
        c.username = 'LYTiT'
      end
      timezone = Timezone::Zone.new :latlon => [latitude, longitude] rescue nil
      self.time_zone = timezone.active_support_time_zone rescue nil
    end

    if self.time_zone_offset == nil
      self.time_zone_offset = Time.now.in_time_zone(self.time_zone).utc_offset/3600.0  rescue nil
    end
    
    self.save
  end

  def self.address_formatter(address, city, state, postal_code, country)
    address = address || "X"
    city = city || "X"
    state = state || "X"
    postal_code = postal_code || "X"
    country = country || "X"

    concat = "#{address}, #{city}, #{state} #{postal_code}, #{country}"
    response = ""
    while response != nil
      response = concat.slice! "X, "
      response = concat.slice! " X"      
    end
    concat.slice! "X, "
    concat.slice! "X,"
    return concat
  end

  #Uniform formatting of venues phone numbers into a "(XXX)-XXX-XXXX" style
  def Venue.formatTelephone(number)
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

  #Temp method to reformat older telephones
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

  def set_open_hours
    venue_foursquare_id = self.foursquare_id

    if venue_foursquare_id == nil
      foursquare_venue = Venue.foursquare_venue_lookup(self.name, self.latitude, self.longitude)
      if foursquare_venue != nil && foursquare_venue != "F2 ERROR"
        venue_foursquare_id = foursquare_venue.id
      else
        if foursquare_venue == "F2 ERROR"
          return {}
        else
          self.update_columns(open_hours: {"NA"=>"NA"})
          return open_hours
        end
      end
    end

    if venue_foursquare_id != nil
      client = Foursquare2::Client.new(:client_id => '35G1RAZOOSCK2MNDOMFQ0QALTP1URVG5ZQ30IXS2ZACFNWN1', :client_secret => 'ZVMBHYP04JOT2KM0A1T2HWLFDIEO1FM3M0UGTT532MHOWPD0', :api_version => '20120610')
      foursquare_venue_with_details = client.venue(venue_foursquare_id) rescue "F2 ERROR"
      if foursquare_venue_with_details == "F2 ERROR"
        return {}
      end
      if foursquare_venue_with_details != nil
        venue_hours = foursquare_venue_with_details.hours
        open_hours_hash = Hash.new
        if venue_hours != nil
          timeframes = venue_hours.timeframes

          for timeframe in timeframes
            days = Venue.create_days_array(timeframe.days)
            for day in days
              open_spans = timeframe.open
              span_hash = Hash.new
              i = 0
              for span in open_spans            
                frame_hash = Hash.new
                open_close_array = Venue.convert_span_to_minutes(span.renderedTime)                      
                frame_hash["frame_"+i.to_s] = {"open_time" => open_close_array.first, "close_time" => open_close_array.last}            
                span_hash.merge!(frame_hash)
                i += 1
              end
              open_hours_hash[day] = span_hash
            end
          end
          self.update_columns(open_hours: open_hours_hash)
        else
          return {} #something went wrong
        end      
      else
        self.update_columns(open_hours: {"NA"=>"NA"})
      end
    else
      self.update_columns(open_hours: {"NA"=>"NA"})
    end
    return open_hours
  end

  def Venue.create_days_array(timeframe_days)
    timeframe_array = timeframe_days.split("–")
    days = Hash.new
    days["Mon"] = 1
    days["Tue"] = 2
    days["Wed"] = 3
    days["Thu"] = 4
    days["Fri"] = 5
    days["Sat"] = 6
    days["Sun"] = 7
    #days = {"Mon" => 1, "Tue" => 2, "Wed"=> 3, "Thu" => 4, "Fri" => 5, "Sat" => 6, "Sun" => 7}
    days_array = []
    commence_day = timeframe_array.first
    end_day = timeframe_array.last
    if days[commence_day] != nil && days[end_day] != nil
      [*days[commence_day]..days[end_day]].each{|day_num| days_array << days.key(day_num)}
    end
    return days_array
  end

  def Venue.convert_span_to_minutes(span)
    span_array=span.split("–")
    opening = span_array.first
    closing = span_array.last

    if opening.last(2) == "AM"
      opening = opening.split(" ").first.gsub(":",".").to_f
    elsif opening == "Midnight"
      opening = 0.0
    elsif opening == "Noon"
      opening = 12.0      
    else
      opening = opening.split(" ").first.gsub(":",".").to_f+12.0
    end

    if closing.last(2) == "PM"
      closing = closing.split(" ").first.gsub(":",".").to_f+12.0
    elsif closing == "Midnight"
      closing = 0.0
    elsif closing == "Noon"
      closing = 12.0
    else
      closing = closing.split(" ").first.gsub(":",".").to_f+24.0
    end

    return [opening, closing]
  end

  def is_open(day, time)
    open_hours = self.hours[day]
    if time >= open_hours["open"] && time <= open_hours["closes"]
      true
    else
      false
    end
  end
  

  #------------------------------------------------------------------------>


  #II. Venue Popularity Ranking Functionality --------------------------------->
  def view(user_id)
    view = VenuePageView.new(:user_id => user_id, :venue_id => self.id, :venue_lyt_sphere =>  self.l_sphere)
    view.save
  end

  def account_page_view(u_id)
    view_half_life = 120.0 #minutes
    latest_page_view_time_wrapper = latest_page_view_time || Time.now
    new_page_view_count = (self.page_views * 2 ** ((-(Time.now - latest_page_view_time_wrapper)/60.0) / (view_half_life))).round(4)+1.0

    self.update_columns(page_views: new_page_view_count)
    self.update_columns(latest_page_view_time: Time.now)
    FeedUser.joins(feed: :feed_venues).where("venue_id = ?", self.id).each{|feed_user| feed_user.update_interest_score(0.05)}
  end

=begin
  def update_linked_list_interest_scores
    linked_list_ids = "SELECT feed_id FROM feed_venues WHERE venue_id = #{self.id}"
    feed_users = FeedUser.where("feed_id IN (?)", linked_list_ids).update_all(interest_score: ) #update using 
  end
=end  

  def update_popularity_rank
    view_half_life = 120.0 #minutes
    latest_page_view_time_wrapper = latest_page_view_time || Time.now
    new_page_view_count = (self.page_views * 2 ** ((-(Time.now - latest_page_view_time_wrapper)/60.0) / (view_half_life))).round(4)
    self.update_columns(page_views: new_page_view_count)
    self.update_columns(popularity_rank: ((self.page_views*0.5+1) * self.rating))
  end

  def ranking_change(new_ranking)
    current_ranking = self.trend_position
    if current_ranking == nil
      return 1
    else
      if new_ranking.to_i == current_ranking.to_i
        return 0
      elsif new_ranking.to_i < current_ranking.to_i
        return 1
      else
        return -1
      end
    end
  end

  def Venue.discover(proximity, previous_venue_ids, user_lat, user_long)
    num_diverse_venues = 50
    nearby_radius = 5000.0 * 1/1000 #* 0.000621371 #meters to miles
    center_point = [user_lat, user_long]
    proximity_box = Geokit::Bounds.from_point_and_radius(center_point, nearby_radius, :units => :kms)

    previous_venue_ids = previous_venue_ids || "0"

    if proximity == "nearby"
      venue = Venue.in_bounds(proximity_box).where("id NOT IN (#{previous_venue_ids}) AND color_rating > -1.0").order("popularity_rank DESC").limit(num_diverse_venues).shuffle.first
      if venue == nil
          if previous_venue_ids == "0"
            venue = Venue.where("(latitude <= #{proximity_box.sw.lat} OR latitude >= #{proximity_box.ne.lat}) OR (longitude <= #{proximity_box.sw.lng} OR longitude >= #{proximity_box.ne.lng}) AND color_rating > -1.0 ").order("popularity_rank DESC").limit(num_diverse_venues).shuffle.first
          else
            venue = []
          end
      end
    else
      venue = Venue.where("(latitude <= #{proximity_box.sw.lat} OR latitude >= #{proximity_box.ne.lat}) OR (longitude <= #{proximity_box.sw.lng} OR longitude >= #{proximity_box.ne.lng}) AND color_rating > -1.0 ").order("popularity_rank DESC").limit(num_diverse_venues).shuffle.first
    end

    return venue

=begin
    if proximity == "nearby"
      #venue = Venue.where("(ACOS(least(1,COS(RADIANS(#{user_lat}))*COS(RADIANS(#{user_long}))*COS(RADIANS(latitude))*COS(RADIANS(longitude))+COS(RADIANS(#{user_lat}))*SIN(RADIANS(#{user_long}))*COS(RADIANS(latitude))*SIN(RADIANS(longitude))+SIN(RADIANS(#{user_lat}))*SIN(RADIANS(latitude))))*6376.77271) 
      #  <= #{nearby_radius}").order("popularity_rank DESC").limit(num_diverse_venues)[rand_position]
      i = 0
      nearby_trending_venues = Venue.in_bounds(proximity_box).where("color_rating > -1.0").order("popularity_rank DESC").limit(num_diverse_venues).shuffle
      
      venue = nearby_trending_venues[i]
      if previous_venue_ids.include?(venue.id) 
        while previous_venue_ids.include?(venue.id)
          i += 1
          venue = nearby_trending_venues[i]
        end
      end
    else
      #venue = Venue.where("(ACOS(least(1,COS(RADIANS(#{user_lat}))*COS(RADIANS(#{user_long}))*COS(RADIANS(latitude))*COS(RADIANS(longitude))+COS(RADIANS(#{user_lat}))*SIN(RADIANS(#{user_long}))*COS(RADIANS(latitude))*SIN(RADIANS(longitude))+SIN(RADIANS(#{user_lat}))*SIN(RADIANS(latitude))))*6376.77271) 
      #  > #{nearby_radius}").order("popularity_rank DESC").limit(num_diverse_venues)[rand_position]
      i = 0
      faraway_trending_venues = Venue.where("(latitude <= #{proximity_box.sw.lat} OR latitude >= #{proximity_box.ne.lat}) OR (longitude <= #{proximity_box.sw.lng} OR longitude >= #{proximity_box.ne.lng}) AND color_rating > -1.0 ").order("popularity_rank DESC").limit(num_diverse_venues).shuffle
      venue = faraway_trending_venues[i]
      if previous_venue_ids.include?(venue.id) 
        while previous_venue_ids.include?(venue.id)
          i += 1
          venue = faraway_trending_venues[i]
        end
      end
    end
    return venue
=end    
  end

  def Venue.trending_venues(user_lat, user_long)
    total_trends = 10
    nearby_ratio = 0.7
    nearby_count = total_trends*nearby_ratio
    global_count = (total_trends-nearby_count)
    center_point = [user_lat, user_long]
    #proximity_box = Geokit::Bounds.from_point_and_radius(center_point, 5, :units => :kms)


    nearby_trends = Venue.close_to(center_point.first, center_point.last, 5000).where("color_rating > -1.0").order("popularity_rank DESC").limit(nearby_count)
    if nearby_trends.count == 0
      global_trends = Venue.far_from(center_point.first, center_point.last, 50*1000).where("color_rating > -1.0").order("popularity_rank DESC").limit(total_trends)
      return global_trends.shuffle
    else
      global_trends = Venue.far_from(center_point.first, center_point.last, 50*1000).where("color_rating > -1.0").order("popularity_rank DESC").limit(global_count)
      return (nearby_trends+global_trends).shuffle
    end
     
  end
  #----------------------------------------------------------------------->


  #III. Instagram Related Functionality --------------------------------------->
  def self.populate_lookup_ids
    v = Venue.where("instagram_location_id IS NOT NULL")
    for v_hat in v 
      if not InstagramLocationIdLookup.where("venue_id = ?", v_hat.id).any?
        InstagramLocationIdLookup.create!(:venue_id => v_hat.id, :instagram_location_id => v_hat.instagram_location_id)
      end
    end
  end

  #name checker for instagram venue creation
  def Venue.name_is_proper?(vname) 
    emoji_and_symbols = ["💗", "❤", "✌", "😊", "😀", "😁", "😂", "😃", "😄", "😅", "😆", "😇", "😈", "👿", "😉", "😊", "☺️", "😋", "😌", "😍", "😎", "😏", "😐", "😑", "😒", "😓", "😔", "😕", "😖", "😗", "😘", "😙", "😚", "😛", "😜", "😝", "😞", "😟", "😠", 
      "😡", "😢", "😣", "😤", "😥", "😦", "😧", "😨", "😩", "😪", "😫", "😬", "😭", "😮", "😯", "😰", "😱", "😲", "😳", "😴", "😵", "😶", "😷", "🙁", "🙂", "😸", "😹", "😺", "😻", "😼", "😽", "😾", "😿", "🙀", "👣", "👤", "👥", "👦", "👧", "👨", "👩", "👨‍",
      "👶", "👷", "👸", "💂", "👼", "🎅", "👻", "👹", "👺", "💩", "💀", "👽", "👾", "🙇", "💁", "🙅", "🙆", "🙋", "🙎", "🙍", "💆", "💇", "💑", "👩‍❤️‍👩", "👨‍❤️‍👨", "💏", "👩‍❤️‍💋‍👩", "👨‍❤️‍💋‍👨", "💅", "👂", "👀", "👃", "👄", "💋", "👅👋", "👍", "👎", "☝️", "👆", "👇", 
      "👈", "👉", "👌", "✌️", "👊", "✊", "✋", "💪", "👐", "🙌", "👏", "🙏", "🖐", "🖕", "🖖", "👦\u{1F3FB}", "👧\u{1F3FB}", "👨\u{1F3FB}", "👩\u{1F3FB}", "👮\u{1F3FB}", "👰\u{1F3FB}", "👱\u{1F3FB}", "👲\u{1F3FB}", "👳\u{1F3FB}", "👴\u{1F3FB}", "👵\u{1F3FB}", "👶\u{1F3FB}", 
      "👷\u{1F3FB}", "👸\u{1F3FB}", "💂\u{1F3FB}", "👼\u{1F3FB}", "🎅\u{1F3FB}", "🙇\u{1F3FB}", "💁\u{1F3FB}", "🙅\u{1F3FB}", "🙆\u{1F3FB}", "🙋\u{1F3FB}", "🙎\u{1F3FB}", "🙍\u{1F3FB}", "💆\u{1F3FB}", "💇\u{1F3FB}", "💅\u{1F3FB}", "👂\u{1F3FB}", "👃\u{1F3FB}", "👋\u{1F3FB}", 
      "👍\u{1F3FB}", "👎\u{1F3FB}", "☝\u{1F3FB}", "👆\u{1F3FB}", "👇\u{1F3FB}", "👈\u{1F3FB}", "👉\u{1F3FB}", "👌\u{1F3FB}", "✌\u{1F3FB}", "👊\u{1F3FB}", "✊\u{1F3FB}", "✋\u{1F3FB}", "💪\u{1F3FB}", "👐\u{1F3FB}", "🙌\u{1F3FB}", "👏\u{1F3FB}", "🙏\u{1F3FB}", "🖐\u{1F3FB}", 
      "🖕\u{1F3FB}", "🖖\u{1F3FB}", "👦\u{1F3FC}", "👧\u{1F3FC}", "👨\u{1F3FC}", "👩\u{1F3FC}", "👮\u{1F3FC}", "👰\u{1F3FC}", "👱\u{1F3FC}", "👲\u{1F3FC}", "👳\u{1F3FC}", "👴\u{1F3FC}", "👵\u{1F3FC}", "👶\u{1F3FC}", "👷\u{1F3FC}", "👸\u{1F3FC}", "💂\u{1F3FC}", "👼\u{1F3FC}", 
      "🎅\u{1F3FC}", "🙇\u{1F3FC}", "💁\u{1F3FC}", "🙅\u{1F3FC}", "🙆\u{1F3FC}", "🙋\u{1F3FC}", "🙎\u{1F3FC}", "🙍\u{1F3FC}", "💆\u{1F3FC}", "💇\u{1F3FC}", "💅\u{1F3FC}", "👂\u{1F3FC}", "👃\u{1F3FC}", "👋\u{1F3FC}", "👍\u{1F3FC}", "👎\u{1F3FC}", "☝\u{1F3FC}", "👆\u{1F3FC}", 
      "👇\u{1F3FC}", "👈\u{1F3FC}", "👉\u{1F3FC}", "👌\u{1F3FC}", "✌\u{1F3FC}", "👊\u{1F3FC}", "✊\u{1F3FC}", "✋\u{1F3FC}", "💪\u{1F3FC}", "👐\u{1F3FC}", "🙌\u{1F3FC}", "👏\u{1F3FC}", "🙏\u{1F3FC}", "🖐\u{1F3FC}", "🖕\u{1F3FC}", "🖖\u{1F3FC}", "👦\u{1F3FD}", "👧\u{1F3FD}", 
      "👨\u{1F3FD}", "👩\u{1F3FD}", "👮\u{1F3FD}", "👰\u{1F3FD}", "👱\u{1F3FD}", "👲\u{1F3FD}", "👳\u{1F3FD}", "👴\u{1F3FD}", "👵\u{1F3FD}", "👶\u{1F3FD}", "👷\u{1F3FD}", "👸\u{1F3FD}", "💂\u{1F3FD}", "👼\u{1F3FD}", "🎅\u{1F3FD}", "🙇\u{1F3FD}", "💁\u{1F3FD}", "🙅\u{1F3FD}", 
      "🙆\u{1F3FD}", "🙋\u{1F3FD}", "🙎\u{1F3FD}", "🙍\u{1F3FD}", "💆\u{1F3FD}", "💇\u{1F3FD}", "💅\u{1F3FD}", "👂\u{1F3FD}", "👃\u{1F3FD}", "👋\u{1F3FD}", "👍\u{1F3FD}", "👎\u{1F3FD}", "☝\u{1F3FD}", "👆\u{1F3FD}", "👇\u{1F3FD}", "👈\u{1F3FD}", "👉\u{1F3FD}", "👌\u{1F3FD}", 
      "✌\u{1F3FD}", "👊\u{1F3FD}", "✊\u{1F3FD}", "✋\u{1F3FD}", "💪\u{1F3FD}", "👐\u{1F3FD}", "🙌\u{1F3FD}", "👏\u{1F3FD}", "🙏\u{1F3FD}", "🖐\u{1F3FD}", "🖕\u{1F3FD}", "🖖\u{1F3FD}", "👦\u{1F3FE}", "👧\u{1F3FE}", "👨\u{1F3FE}", "👩\u{1F3FE}", "👮\u{1F3FE}", "👰\u{1F3FE}", 
      "👱\u{1F3FE}", "👲\u{1F3FE}", "👳\u{1F3FE}", "👴\u{1F3FE}", "👵","\u{1F3FE}", "👶","\u{1F3FE}", "👷","\u{1F3FE}", "👸","\u{1F3FE}", "💂","\u{1F3FE}", "👼","\u{1F3FE}", "🎅","\u{1F3FE}", "🙇","\u{1F3FE}", "💁","\u{1F3FE}", "🙅","\u{1F3FE}", "🙆","\u{1F3FE}", "🙋","\u{1F3FE}", 
      "🙎","\u{1F3FE}", "🙍","\u{1F3FE}", "💆","\u{1F3FE}", "💇","\u{1F3FE}", "💅","\u{1F3FE}", "👂","\u{1F3FE}", "👃","\u{1F3FE}", "👋","\u{1F3FE}", "👍","\u{1F3FE}", "👎","\u{1F3FE}", "☝","\u{1F3FE}", "👆","\u{1F3FE}", "👇","\u{1F3FE}", "👈","\u{1F3FE}", "👉","\u{1F3FE}", "👌",
      "\u{1F3FE}", "✌\u{1F3FE}", "👊","\u{1F3FE}", "✊","\u{1F3FE}", "✋","\u{1F3FE}", "💪","\u{1F3FE}", "👐\u{1F3FE}", "🙌\u{1F3FE}", "👏\u{1F3FE}", "🙏\u{1F3FE}", "🖐\u{1F3FE}", "🖕\u{1F3FE}", "🖖\u{1F3FE}", "👦\u{1F3FE}", "👧\u{1F3FE}", "👨\u{1F3FE}", "👩\u{1F3FE}", "👮\u{1F3FE}", 
      "👰\u{1F3FE}", "👱\u{1F3FE}", "👲\u{1F3FE}", "👳\u{1F3FE}", "👴\u{1F3FE}", "👵\u{1F3FE}", "👶\u{1F3FE}", "👷\u{1F3FE}", "👸\u{1F3FE}", "💂\u{1F3FE}", "👼\u{1F3FE}", "🎅\u{1F3FE}", "🙇\u{1F3FE}", "💁\u{1F3FE}", "🙅\u{1F3FE}", "🙆\u{1F3FE}", "🙋\u{1F3FE}", "🙎\u{1F3FE}", "🙍\u{1F3FE}", 
      "💆\u{1F3FE}", "💇\u{1F3FE}", "💅\u{1F3FE}", "👂\u{1F3FE}", "👃\u{1F3FE}", "👋\u{1F3FE}", "👍\u{1F3FE}", "👎\u{1F3FE}", "☝\u{1F3FE}", "👆\u{1F3FE}", "👇\u{1F3FE}", "👈\u{1F3FE}", "👉\u{1F3FE}", "👌\u{1F3FE}", "✌\u{1F3FE}", "👊\u{1F3FE}", "✊\u{1F3FE}", "✋\u{1F3FE}", "💪\u{1F3FE}", 
      "👐\u{1F3FE}", "🙌\u{1F3FE}", "👏\u{1F3FE}", "🙏\u{1F3FE}", "🖐\u{1F3FE}", "🖕\u{1F3FE}", "🖖\u{1F3FE}", "🌱", "🌲", "🌳", "🌴", "🌵", "🌷", "🌸", "🌹", "🌺", "🌻", "🌼", "💐", "🌾", "🌿", "🍀", "🍁", "🍂", "🍃", "🍄", "🌰", "🐀", "🐁", "🐭", "🐹", "🐂", "🐃", "🐄", "🐮", "🐅", 
      "🐆", "🐯", "🐇", "🐰", "🐈", "🐱", "🐎", "🐴", "🐏", "🐑", "🐐", "🐓", "🐔", "🐤", "🐣", "🐥", "🐦", "🐧", "🐘", "🐪", "🐫", "🐗", "🐖", "🐷", "🐽", "🐕", "🐩", "🐶", "🐺", "🐻", "🐨", "🐼", "🐵", "🙈", "🙉", "🙊", "🐒", "🐉", "🐲", "🐊", "🐍", "🐢", "🐸", "🐋", "🐳", "🐬", 
      "🐙", "🐟", "🐠", "🐡", "🐚", "🐌", "🐛", "🐜", "🐝", "🐞", "🐾", "⚡️", "🔥", "🌙", "☀️", "⛅️", "☁️", "💧", "💦", "☔️", "💨", "❄️", "🌟", "⭐️", "🌠", "🌄", "🌅", "🌈", "🌊", "🌋", "🌌", "🗻", "🗾", "🌐", "🌍", "🌎", "🌏", "🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘", "🌚", "🌝", 
      "🌛", "🌜", "🌞", "🍅", "🍆", "🌽", "🍠", "🍇", "🍈", "🍉", "🍊", "🍋", "🍌", "🍍", "🍎", "🍏", "🍐", "🍑", "🍒", "🍓", "🍔", "🍕", "🍖", "🍗", "🍘", "🍙", "🍚", "🍛", "🍜", "🍝", "🍞", "🍟", "🍡", "🍢", "🍣", "🍤", "🍥", "🍦", "🍧", "🍨", "🍩", "🍪", "🍫", "🍬", "🍭", "🍮", 
      "🍯", "🍰", "🍱", "🍲", "🍳", "🍴", "🍵", "☕️", "🍶", "🍷", "🍸", "🍹", "🍺", "🍻", "🍼🎀", "🎁", "🎂", "🎃", "🎄", "🎋", "🎍", "🎑", "🎆", "🎇", "🎉", "🎊", "🎈", "💫", "✨", "💥", "🎓", "👑", "🎎", "🎏", "🎐", "🎌", "🏮", "💍", "❤️", "💔", "💌", "💕", "💞", "💓", "💗", "💖", 
      "💘", "💝", "💟", "💜", "💛", "💚", "💙", "🏃", "🚶", "💃", "🚣", "🏊", "🏄", "🛀", "🏂", "🎿", "⛄️", "🚴", "🚵", "🏇", "⛺️", "🎣", "⚽️", "🏀", "🏈", "⚾️", "🎾", "🏉", "⛳️", "🏆", "🎽", "🏁", "🎹", "🎸", "🎻", "🎷", "🎺", "🎵", "🎶", "🎼", "🎧", "🎤", "🎭", "🎫", "🎩", "🎪", 
      "🎬", "🎨", "🎯", "🎱", "🎳", "🎰", "🎲", "🎮", "🎴", "🃏", "🀄️", "🎠", "🎡", "🎢", "🚃", "🚞", "🚂", "🚋", "🚝", "🚄", "🚅", "🚆", "🚇", "🚈", "🚉", "🚊", "🚌", "🚍", "🚎", "🚐", "🚑", "🚒", "🚓", "🚔", "🚨", "🚕", "🚖", "🚗", "🚘", "🚙", "🚚", "🚛", "🚜", "🚲", "🚏", "⛽️", 
      "🚧", "🚦", "🚥", "🚀", "🚁", "✈️", "💺", "⚓️", "🚢", "🚤", "⛵️", "🚡", "🚠", "🚟", "🛂", "🛃", "🛄", "🛅", "💴", "💶", "💷", "💵", "🗽", "🗿", "🌁", "🗼", "⛲️", "🏰", "🏯", "🌇", "🌆", "🌃", "🌉", "🏠", "🏡", "🏢", "🏬", "🏭", "🏣", "🏤", "🏥", "🏦", "🏨", "🏩", "💒", "⛪️", 
      "🏪", "🏫", "🇦🇺", "🇦🇹", "🇧🇪", "🇧🇷", "🇨🇦", "🇨🇱", "🇨🇳", "🇨🇴", "🇩🇰", "🇫🇮", "🇫🇷", "🇩🇪", "🇭🇰", "🇮🇳", "🇮🇩", "🇮🇪", "🇮🇱", "🇮🇹", "🇯🇵", "🇰🇷", "🇲🇴", "🇲🇾", "🇲🇽", "🇳🇱", "🇳🇿", "🇳🇴", "🇵🇭", "🇵🇱", "🇵🇹", "🇵🇷", "🇷🇺", "🇸🇦", 
      "🇸🇬", "🇿🇦", "🇪🇸", "🇸🇪", "🇨🇭", "🇹🇷", "🇬🇧", "🇺🇸", "🇦🇪", "🇻🇳", "⌚️", "📱", "📲", "💻", "⏰", "⏳", "⌛️", "📷", "📹", "🎥", "📺", "📻", "📟", "📞", "☎️", "📠", "💽", "💾", "💿", "📀", "📼", "🔋", "🔌", "💡", "🔦", "📡", "💳", "💸", "💰", "💎⌚️", "📱", "📲", 
      "💻", "⏰", "⏳", "⌛️", "📷", "📹", "🎥", "📺", "📻", "📟", "📞", "☎️", "📠", "💽", "💾", "💿", "📀", "📼", "🔋", "🔌", "💡", "🔦", "📡", "💳", "💸", "💰", "💎🚪", "🚿", "🛁", "🚽", "💈", "💉", "💊", "🔬", "🔭", "🔮", "🔧", "🔪", "🔩", "🔨", "💣", "🚬", "🔫", "🔖", "📰", "🔑", 
      "✉️", "📩", "📨", "📧", "📥", "📤", "📦", "📯", "📮", "📪", "📫", "📬", "📭", "📄", "📃", "📑", "📈", "📉", "📊", "📅", "📆", "🔅", "🔆", "📜", "📋", "📖", "📓", "📔", "📒", "📕", "📗", "📘", "📙", "📚", "📇", "🔗", "📎", "📌", "✂️", "📐", "📍", "📏", "🚩", "📁", "📂", "✒️", "✏️", 
      "📝", "🔏", "🔐", "🔒", "🔓", "📣", "📢", "🔈", "🔉", "🔊", "🔇", "💤", "🔔", "🔕", "💭", "💬", "🚸", "🔍", "🔎", "🚫", "⛔️", "📛", "🚷", "🚯", "🚳", "🚱", "📵", "🔞", "🉑", "🉐", "💮", "㊙️", "㊗️", "🈴", "🈵", "🈲", "🈶", "🈚️", "🈸", "🈺", "🈷", "🈹", "🈳", "🈂", "🈁", 
      "🈯️", "💹", "❇️", "✳️", "❎", "✅", "✴️", "📳", "📴", "🆚", "🅰", "🅱", "🆎", "🆑", "🅾", "🆘", "🆔", "🅿️", "🚾", "🆒", "🆓", "🆕", "🆖", "🆗", "🆙", "🏧", "♈️", "♉️", "♊️", "♋️", "♌️", "♍️", "♎️", "♏️", "♐️", "♑️", "♒️", "♓️", "🚻", "🚹", "🚺", "🚼", "♿️", "🚰", "🚭", "🚮", "▶️", "◀️", "🔼", "🔽", 
      "⏩", "⏪", "⏫", "⏬", "➡️", "⬅️", "⬆️", "⬇️", "↗️", "↘️", "↙️", "↖️", "↕️", "↔️", "🔄", "↪️", "↩️", "⤴️", "⤵️", "🔀", "🔁", "🔂", "#️⃣", "0️⃣", "1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣", "6️⃣", "7️⃣", "8️⃣", "9️⃣", "🔟", "🔢", "🔤", "🔡", "🔠", "ℹ️", "📶", "🎦", "🔣", "➕", "➖", "〰", "➗", "✖️", "✔️", 
      "🔃", "™", "©", "®", "💱", "💲", "➰", "➿", "〽️", "❗️", "❓", "❕", "❔", "‼️", "⁉️", "❌", "⭕️", "💯", "🔚", "🔙", "🔛", "🔝", "🔜", "🌀", "Ⓜ️", "⛎", "🔯", "🔰", "🔱", "⚠️", "♨️", "♻️", "💢", "💠", "♠️", "♣️", "♥️", "♦️", "☑️", "⚪️", "⚫️", "🔘", "🔴", "🔵", "🔺", "🔻", "🔸", "🔹", "🔶", 
      "🔷", "▪️", "▫️", "⬛️", "⬜️", "◼️", "◻️", "◾️", "◽️", "🔲", "🔳", "🕐", "🕑", "🕒", "🕓", "🕔", "🕕", "🕖", "🕗", "🕘", "🕙", "🕚", "🕛", "🕜", "🕝", "🕞", "🕟", "🕠", "🕡", "🕢", "🕣", "🕤", "🕥", "🕦", "🕧", "🌡", "🌢", "🌣", "🌤", "🌥", "🌦", "🌧", "🌨", "🌩", "🌪", "🌫", "🌬", "🌶",  
      "🛌", "🛍", "🛎", "🛏", "🛠", "🛡", "🛢", "🛣", "🛤", "🛥", "🛦", "🛧", "🛨", "🛩", "🛪", "🛫", "🛬", "🛰", "🛱", "🛲", "🛳"] 
    regex_1 = /[\u{203C}\u{2049}\u{20E3}\u{2122}\u{2139}\u{2194}-\u{2199}\u{21A9}-\u{21AA}\u{231A}-\u{231B}\u{23E9}-\u{23EC}\u{23F0}\u{23F3}\u{24C2}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}\u{2600}-\u{2601}\u{260E}\u{2611}\u{2614}-\u{2615}\u{261D}\u{263A}\u{2648}-\u{2653}\u{2660}\u{2663}\u{2665}-\u{2666}\u{2668}\u{267B}\u{267F}\u{2693}\u{26A0}-\u{26A1}\u{26AA}-\u{26AB}\u{26BD}-\u{26BE}\u{26C4}-\u{26C5}\u{26CE}\u{26D4}\u{26EA}\u{26F2}-\u{26F3}\u{26F5}\u{26FA}\u{26FD}\u{2702}\u{2705}\u{2708}-\u{270C}\u{270F}\u{2712}\u{2714}\u{2716}\u{2728}\u{2733}-\u{2734}\u{2744}\u{2747}\u{274C}\u{274E}\u{2753}-\u{2755}\u{2757}\u{2764}\u{2795}-\u{2797}\u{27A1}\u{27B0}\u{2934}-\u{2935}\u{2B05}-\u{2B07}\u{2B1B}-\u{2B1C}\u{2B50}\u{2B55}\u{3030}\u{303D}\u{3297}\u{3299}\u{1F004}\u{1F0CF}\u{1F170}-\u{1F171}\u{1F17E}-\u{1F17F}\u{1F18E}\u{1F191}-\u{1F19A}\u{1F1E7}-\u{1F1EC}\u{1F1EE}-\u{1F1F0}\u{1F1F3}\u{1F1F5}\u{1F1F7}-\u{1F1FA}\u{1F201}-\u{1F202}\u{1F21A}\u{1F22F}\u{1F232}-\u{1F23A}\u{1F250}-\u{1F251}\u{1F300}-\u{1F320}\u{1F330}-\u{1F335}\u{1F337}-\u{1F37C}\u{1F380}-\u{1F393}\u{1F3A0}-\u{1F3C4}\u{1F3C6}-\u{1F3CA}\u{1F3E0}-\u{1F3F0}\u{1F400}-\u{1F43E}\u{1F440}\u{1F442}-\u{1F4F7}\u{1F4F9}-\u{1F4FC}\u{1F500}-\u{1F507}\u{1F509}-\u{1F53D}\u{1F550}-\u{1F567}\u{1F5FB}-\u{1F640}\u{1F645}-\u{1F64F}\u{1F680}-\u{1F68A}]/
    regex_2 = /[\u{00A9}\u{00AE}\u{203C}\u{2049}\u{2122}\u{2139}\u{2194}-\u{2199}\u{21A9}-\u{21AA}\u{231A}-\u{231B}\u{2328}\u{23CF}\u{23E9}-\u{23F3}\u{23F8}-\u{23FA}\u{24C2}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}\u{2600}-\u{2604}\u{260E}\u{2611}\u{2614}-\u{2615}\u{2618}\u{261D}\u{2620}\u{2622}-\u{2623}\u{2626}\u{262A}\u{262E}-\u{262F}\u{2638}-\u{263A}\u{2648}-\u{2653}\u{2660}\u{2663}\u{2665}-\u{2666}\u{2668}\u{267B}\u{267F}\u{2692}-\u{2694}\u{2696}-\u{2697}\u{2699}\u{269B}-\u{269C}\u{26A0}-\u{26A1}\u{26AA}-\u{26AB}\u{26B0}-\u{26B1}\u{26BD}-\u{26BE}\u{26C4}-\u{26C5}\u{26C8}\u{26CE}-\u{26CF}\u{26D1}\u{26D3}-\u{26D4}\u{26E9}-\u{26EA}\u{26F0}-\u{26F5}\u{26F7}-\u{26FA}\u{26FD}\u{2702}\u{2705}\u{2708}-\u{270D}\u{270F}\u{2712}\u{2714}\u{2716}\u{271D}\u{2721}\u{2728}\u{2733}-\u{2734}\u{2744}\u{2747}\u{274C}\u{274E}\u{2753}-\u{2755}\u{2757}\u{2763}-\u{2764}\u{2795}-\u{2797}\u{27A1}\u{27B0}\u{27BF}\u{2934}-\u{2935}\u{2B05}-\u{2B07}\u{2B1B}-\u{2B1C}\u{2B50}\u{2B55}\u{3030}\u{303D}\u{3297}\u{3299}\u{1F004}\u{1F0CF}\u{1F170}-\u{1F171}\u{1F17E}-\u{1F17F}\u{1F18E}\u{1F191}-\u{1F19A}\u{1F201}-\u{1F202}\u{1F21A}\u{1F22F}\u{1F232}-\u{1F23A}\u{1F250}-\u{1F251}\u{1F300}-\u{1F321}\u{1F324}-\u{1F393}\u{1F396}-\u{1F397}\u{1F399}-\u{1F39B}\u{1F39E}-\u{1F3F0}\u{1F3F3}-\u{1F3F5}\u{1F3F7}-\u{1F4FD}\u{1F4FF}-\u{1F53D}\u{1F549}-\u{1F54E}\u{1F550}-\u{1F567}\u{1F56F}-\u{1F570}\u{1F573}-\u{1F579}\u{1F587}\u{1F58A}-\u{1F58D}\u{1F590}\u{1F595}-\u{1F596}\u{1F5A5}\u{1F5A8}\u{1F5B1}-\u{1F5B2}\u{1F5BC}\u{1F5C2}-\u{1F5C4}\u{1F5D1}-\u{1F5D3}\u{1F5DC}-\u{1F5DE}\u{1F5E1}\u{1F5E3}\u{1F5EF}\u{1F5F3}\u{1F5FA}-\u{1F64F}\u{1F680}-\u{1F6C5}\u{1F6CB}-\u{1F6D0}\u{1F6E0}-\u{1F6E5}\u{1F6E9}\u{1F6EB}-\u{1F6EC}\u{1F6F0}\u{1F6F3}\u{1F910}-\u{1F918}\u{1F980}-\u{1F984}\u{1F9C0}]/
   
    vname_emoji_strip_1 = vname.gsub regex_1, ''
    vname_emoji_strip_2 = vname_emoji_strip_1.gsub regex_2, '' 

    if not vname
      result = false
    #genuine locations have proper text formatting 
    elsif vname.downcase == vname || vname.upcase == vname
      result = false
    #check for emojis
    elsif vname.length != vname_emoji_strip_2.length
      result = false
    elsif vname.strip.last == "."
      result = false
    elsif (vname.downcase.include? "www.") || (vname.downcase.include? ".com") || (vname.downcase.include? "http://") || (vname.downcase.include? "https://")
      result = false
    elsif (vname.downcase.include? "|") || (vname.downcase.include? "#") || (vname.downcase.include? ";")
      result = false
    elsif (vname.downcase.include? "snapchat") || (vname.downcase.include? "whatsapp") || (vname.downcase.include? "viber") || (vname.downcase.include? "sms")
      result = false
    elsif (vname.downcase.include? ",") || (vname.downcase.include? "(") || (vname.downcase.include? ")")
      result = false
    elsif (vname.downcase.split & emoji_and_symbols).count != 0
      result = false
    elsif vname != vname.titlecase
      result = false
    else
      result = true
    end
    return result
  end

  def Venue.validate_venue(venue_name, venue_lat, venue_long, venue_instagram_location_id, origin_vortex)
    client = Foursquare2::Client.new(:client_id => '35G1RAZOOSCK2MNDOMFQ0QALTP1URVG5ZQ30IXS2ZACFNWN1', :client_secret => 'ZVMBHYP04JOT2KM0A1T2HWLFDIEO1FM3M0UGTT532MHOWPD0', :api_version => '20120610')
    #Used to establish if a location tied to an Instagram is legitimate and not a fake, "Best Place Ever" type one.
    #Returns a venue object if location is valid, otherwise nil. Primary check occurs through a Froursquare lookup.
    if Venue.name_is_proper?(venue_name)
      #strip city from name if present
      lytit_venue_lookup = Venue.fetch_venues_for_instagram_pull(venue_name, venue_lat, venue_long, venue_instagram_location_id, origin_vortex)

      if lytit_venue_lookup == nil
        #scrub the name of such things like appended city. Foursquare does not handle such queries well.i.e F2 will not recognize 'Marquee New York' as 'Marquee'.
        scrubbed_venue_name = Venue.scrub_venue_name(venue_name, origin_vortex)
        foursquare_venue = Venue.foursquare_venue_lookup(scrubbed_venue_name, venue_lat, venue_long)
          #no corresponding venue found in Foursquare database
        if foursquare_venue == nil
          return nil
        else
          new_lytit_venue = Venue.create_new_db_entry(venue_name, nil, nil, nil, nil, nil, nil, venue_lat, venue_long, venue_instagram_location_id, origin_vortex)
          new_lytit_venue.update_columns(foursquare_id: foursquare_venue.id)
          new_lytit_venue.update_columns(verified: true)
          InstagramLocationIdLookup.delay.create!(:venue_id => new_lytit_venue.id, :instagram_location_id => venue_instagram_location_id)
          return new_lytit_venue
        end
      else
        if lytit_venue_lookup.verified == true
          return lytit_venue_lookup
        else
          lytit_venue_lookup.delete
          return nil
        end
      end
    else
      nil
    end
  end

  def Venue.foursquare_venue_lookup(venue_name, venue_lat, venue_long)
    client = Foursquare2::Client.new(:client_id => '35G1RAZOOSCK2MNDOMFQ0QALTP1URVG5ZQ30IXS2ZACFNWN1', :client_secret => 'ZVMBHYP04JOT2KM0A1T2HWLFDIEO1FM3M0UGTT532MHOWPD0', :api_version => '20120610')
    foursquare_search_results = client.search_venues(:ll => "#{venue_lat},#{venue_long}", :query => venue_name) rescue "F2 ERROR"
    if foursquare_search_results != "F2 ERROR" and (foursquare_search_results.first != nil and foursquare_search_results.first.last.count > 0)
      foursquare_venue = foursquare_search_results.first.last.first
      if venue_name.include?(foursquare_venue.name) == false && (foursquare_venue.name).include?(venue_name) == false        
        require 'fuzzystringmatch'
        jarow = FuzzyStringMatch::JaroWinkler.create( :native )
        jarow_winkler_proximity = p jarow.getDistance(venue_name, foursquare_venue.name)
        if jarow_winkler_proximity < 0.7
          foursquare_venue = nil
          for entry in foursquare_search_results.first.last
            jarow_winkler_proximity = p jarow.getDistance(venue_name, entry.name)
            if jarow_winkler_proximity >= 0.7
              foursquare_venue = entry
            end
          end
        end
      end

      return foursquare_venue
    else
      if foursquare_search_results == "F2 ERROR"
        return "F2 ERROR"
      else
        return nil
      end
    end
  end

  def set_instagram_location_id(search_radius)
    #Set-up of tools to be used
    require 'fuzzystringmatch'
    jarow = FuzzyStringMatch::JaroWinkler.create( :native )    
    if search_radius == nil
      search_radius = 100
    end
    search_hash = Hash.new #has the from [match_strength] => instagram_location_id where match_strength is a function of a returned instagrams
    wide_area_search = false
    occurence_multiplier = 1.15 #if a location shows up more than once in the instagram pull return statement and is of certain string closeness to an entry we amplify it match_score
    
    #We must identify landmarks, parks, etc. because of their large areas and pull instagrams from a bigger radius. Most of these types
    #of locations will not have a specific address, city or particularly postal code because of their size.
    if (self.address == nil || self.city == nil) || self.postal_code == nil 
      nearby_instagram_content = Instagram.media_search(latitude, longitude, :distance => 5000, :count => 100) #, :min_timestamp => (Time.now-48.hours).to_time.to_i)
      wide_area_search = true
    else
      #Dealing with an establishment so can afford a smaller pull radius.
      nearby_instagram_content = Instagram.media_search(latitude, longitude, :distance => search_radius, :count => 100)
    end

    if nearby_instagram_content.count > 0
      for instagram in nearby_instagram_content
        if instagram.location.name != nil
          puts("#{instagram.location.name}, #{instagram.location.id}")
          #when working with proper names words like "the" and "a" hinder accuracy    
          instagram_location_name_clean = instagram.location.name.downcase.gsub("the", "").gsub("café", "").gsub(" a ", "").gsub("cafe", "").gsub("restaurant", "").gsub("club", "").gsub("bar", "").gsub("downtown", "").gsub("updtown", "").gsub("park", "").gsub("national", "").gsub(" ", "")
          venue_name_clean = self.name.downcase.gsub("the", "").gsub(" a ", "").gsub("café", "").gsub("cafe", "").gsub("restaurant", "").gsub("club", "").gsub("bar", "").gsub("downtown", "").gsub("updtown", "").gsub("park", "").gsub("national", "").gsub(" ", "")
          jarow_winkler_proximity = p jarow.getDistance(instagram_location_name_clean, venue_name_clean)

          if jarow_winkler_proximity > 0.70 && ((self.name.downcase.include?("park") == true && instagram.location.name.downcase.include?("park")) == true || (self.name.downcase.include?("park") == false && instagram.location.name.downcase.include?("park") == false))
            if not search_hash[instagram.location.id]
              search_hash[instagram.location.id] = jarow_winkler_proximity
            else
              previous_score = search_hash[instagram.location.id]
              search_hash[instagram.location.id] = previous_score * occurence_multiplier
            end
          
          end
        end
      end

      if search_hash.count > 0
        best_location_match_id = search_hash.max_by{|k,v| v}.first
        self.update_columns(instagram_location_id: best_location_match_id)
        if InstagramLocationIdLookup.find_by_instagram_location_id(best_location_match_id) == nil
          inst_location_id_tracker_lookup_entry = InstagramLocationIdLookup.new(:venue_id => self.id, :instagram_location_id => best_location_match_id)
          inst_location_id_tracker_lookup_entry.save
        end

        #the proper instagram location id has been determined now we go back and traverse the pulled instagrams to filter out the instagrams
        #we need and create venue comments
        venue_comments_created = 0
        venue_instagrams = []
        for instagram in nearby_instagram_content
          if instagram.location.id == self.instagram_location_id && DateTime.strptime("#{instagram.created_time}",'%s') >= Time.now - 24.hours
            venue_instagrams << instagram.to_hash
          end
        end
        VenueComment.delay.convert_bulk_instagrams_to_vcs(venue_instagrams, self)

        #if little content is offered on the geo pull make a venue specific pull
        if venue_instagrams.count < 3
          puts ("making a venue get instagrams calls")
          venue_instagrams.concat(self.get_instagrams(true))
          #venue_instagrams.flatten!
          #to preserve API calls if we make a call now a longer period must pass before making another pull of a venue's instagram comments
          self.update_columns(last_instagram_pull_time: Time.now + 15.minutes)
        else
          self.update_columns(last_instagram_pull_time: Time.now)
        end
      else
        #recursive call with slightly bigger radius for venue searches
        if search_radius != 250 && wide_area_search != true
          set_instagram_location_id(250)
        else
          self.update_columns(instagram_location_id: 0)
        end
      end
    else
      #recursive call with slightly bigger radius for venue searches
      if search_radius != 250 && wide_area_search != true
        set_instagram_location_id(250)
      else
        self.update_columns(instagram_location_id: 0)
      end
    end

    if venue_instagrams != nil and venue_instagrams.first.nil?
      venue_instagrams.sort_by!{|instagram| -(instagram["created_time"].to_i)}
    end

    return venue_instagrams
  end


  #Instagram API locational content pulls. The min_id_consideration variable is used because we also call get_instagrams sometimes when setting an instagram location id (see bellow) and thus 
  #need access to all recent instagrams
  def get_instagrams(day_pull)
    last_instagram_id = nil

    instagrams = instagram_location_ping(day_pull, false)

    if instagrams.count > 0
      #instagrams.sort_by!{|instagram| -(instagram.created_time.to_i)}
      #instagrams.map!(&:to_hash)
      VenueComment.delay.convert_bulk_instagrams_to_vcs(instagrams, self)
    else
      instagrams = []
    end

    return instagrams
  end

  def instagram_location_ping(day_pull, hourly_pull)
    instagram_access_token_obj = InstagramAuthToken.where("is_valid IS TRUE").sample(1).first
    instagram_access_token = instagram_access_token_obj.token rescue nil
    if instagram_access_token != nil
      instagram_access_token_obj.increment!(:num_used, 1) rescue nil
    end
    client = Instagram.client(:access_token => instagram_access_token)

    instagrams = []
    if (day_pull == true || ((last_instagram_pull_time == nil or last_instagram_pull_time <= Time.now - 24.hours) || self.last_instagram_post == nil)) && hourly_pull == false
      instagrams = client.location_recent_media(self.instagram_location_id, :min_timestamp => (Time.now-24.hours).to_time.to_i).map(&:to_hash) rescue self.rescue_instagram_api_call(instagram_access_token, day_pull, false).map(&:to_hash)
      self.update_columns(last_instagram_pull_time: Time.now)
    elsif hourly_pull == true 
      instagrams = client.location_recent_media(self.instagram_location_id, :min_timestamp => (Time.now-1.hour).to_time.to_i) rescue self.rescue_instagram_api_call(instagram_access_token, false, true)
      self.update_columns(last_instagram_pull_time: Time.now)
    else
      instagrams = client.location_recent_media(self.instagram_location_id, :min_id => self.last_instagram_post).map(&:to_hash) rescue self.rescue_instagram_api_call(instagram_access_token, day_pull, false)
      self.update_columns(last_instagram_pull_time: Time.now)
    end

    if instagrams != nil
      return instagrams
    else
      return []
    end
  end

  def rescue_instagram_api_call(invalid_instagram_access_token, day_pull, hourly_pull)
    if invalid_instagram_access_token != nil
      InstagramAuthToken.find_by_token(invalid_instagram_access_token).update_columns(is_valid: false)
    end

    if day_pull == true
      Instagram.location_recent_media(self.instagram_location_id, :min_timestamp => (Time.now-24.hours).to_time.to_i)
    else
      if self.last_instagram_post != nil && hourly_pull == false
        Instagram.location_recent_media(self.instagram_location_id, :min_id => self.last_instagram_post).map(&:to_hash) rescue []
      else
        if hourly_pull == true
          Instagram.location_recent_media(self.instagram_location_id, :min_timestamp => (Time.now-1.hour).to_time.to_i) rescue []
        else
          Instagram.location_recent_media(self.instagram_location_id, :min_timestamp => (Time.now-24.hours).to_time.to_i).map(&:to_hash) rescue []
        end
      end
    end
  end

  def self.get_comments(venue_ids)    
    if venue_ids.count > 1
    #returning cluster comments which is just a pull of all avaliable underlying venue comments
      return VenueComment.where("venue_id IN (?)", venue_ids).order("time_wrapper desc")
    else
    #dealing with an individual venue which could require an instagram pull
      venue = Venue.find_by_id(venue_ids.first)
      new_instagrams = []

      new_instagrams = venue.update_comments

      #new_instagrams.sort_by{|instagram| instagram["created_time"].reverse}
      if new_instagrams != nil and new_instagrams.first.is_a?(Hash) == true
        lytit_vcs = venue.venue_comments.order("time_wrapper DESC")
        if lytit_vcs.first != nil
          new_instagrams.concat(lytit_vcs)
        end
        #total_media.flatten!
        return Kaminari.paginate_array(new_instagrams) #Kaminari.paginate_array(total_media.sort_by{|post| VenueComment.implicit_created_at(post)}.reverse)
      else
        return venue.venue_comments.order("time_wrapper DESC")
      end
    end
  end

  def update_comments
      instagram_refresh_rate = 10 #minutes
      instagram_venue_id_ping_rate = 1 #days      

      if self.instagram_location_id != nil && self.last_instagram_pull_time != nil
        #try to establish instagram location id if previous attempts failed every 1 day
        if self.instagram_location_id == 0 
          if self.latest_posted_comment_time != nil and ((Time.now - instagram_venue_id_ping_rate.days >= self.latest_posted_comment_time) && (Time.now - (instagram_venue_id_ping_rate/2.0).days >= self.last_instagram_pull_time))
            new_instagrams = self.set_instagram_location_id(100)
            self.update_columns(last_instagram_pull_time: Time.now)
          end
        elsif self.latest_posted_comment_time != nil and (Time.now - instagram_venue_id_ping_rate.days >= self.last_instagram_pull_time)
            new_instagrams = self.set_instagram_location_id(100)
            self.update_columns(last_instagram_pull_time: Time.now)
        else
          if ((Time.now - instagram_refresh_rate.minutes) >= self.last_instagram_pull_time)
            new_instagrams = self.get_instagrams(false)
          end
        end
      else
        new_instagrams = self.set_instagram_location_id(100)
        self.update_columns(last_instagram_pull_time: Time.now)
      end
      new_instagrams
  end


  def instagram_pull_check
    instagram_refresh_rate = 15 #minutes
    instagram_venue_id_ping_rate = 1 #days

    if self.instagram_location_id != nil && self.last_instagram_pull_time != nil
      #try to establish instagram location id if previous attempts failed every 1 day
      if self.instagram_location_id == 0 
        if ((Time.now - instagram_venue_id_ping_rate.minutes) >= self.last_instagram_pull_time)
          self.set_instagram_location_id(100)
          self.update_columns(last_instagram_pull_time: Time.now)
        end
      else
        #if 5 minutes remain till the instagram refresh rate pause is met we make a delayed called since the content in the VP is fresh enough and we do not want to 
        #keep the client waiting for an Instagram API response
        if ((Time.now - (instagram_refresh_rate-5).minutes) > self.last_instagram_pull_time) && ((Time.now - instagram_refresh_rate.minutes) < self.last_instagram_pull_time)
          new_media_created = self.delay.get_instagrams(false)
        end

        #if more than or equal to instagram refresh rate pause time has passed then we make the client wait a bit longer but deliver fresh content (no delayed job used)
        if ((Time.now - instagram_refresh_rate.minutes) >= self.last_instagram_pull_time)
            new_media_created = self.get_instagrams(false)
        end
      end
    else
      if self.instagram_location_id == nil
        self.set_instagram_location_id(100)
      elsif self.instagram_location_id != 0
        new_media_created = self.get_instagrams(false)
      else
        new_media_created = false
      end
    end
  end

  def self.instagram_content_pull(lat, long)
    if lat != nil && long != nil
      
      surrounding_lyts_radius = 10000 * 1/1000
      if not Venue.within(surrounding_lyts_radius.to_f, :units => :kms, :origin => [lat, long]).where("rating > 0").any? #Venue.within(Venue.meters_to_miles(surrounding_lyts_radius.to_i), :origin => [lat, long]).where("rating > 0").any?
        new_instagrams = Instagram.media_search(lat, long, :distance => 5000, :count => 100, :min_timestamp => (Time.now-24.hours).to_time.to_i)

        #If more than 70 Instagram in area over the past day we do a vortex proximity check to see if one needs to be dropped
        if new_instagrams.count > 70
          InstagramVortex.check_nearby_vortex_existence(lat, long)
        end

        for instagram in new_instagrams
          #VenueComment.convert_instagram_to_vc(instagram, nil, nil)
          VenueComment.create_vc_from_instagram(instagram.to_hash, nil, nil, true)
        end
      end
    end

  end

  def self.initial_list_instagram_pull(initial_list_venue_ids)
    venues = Venue.where("id IN (#{initial_list_venue_ids}) AND instagram_location_id IS NOT NULL").limit(10)
    for venue in venues
      if venue.latest_posted_comment_time < (Time.now - 1.hour)
        #pull insts from instagram and convert immediately to vcs
        instagrams = venue.instagram_location_ping(false, true)
        if instagrams.length > 0
          instagrams.sort_by!{|instagram| -(instagram.created_time.to_i)} rescue nil
          venue.set_last_venue_comment_details(instagrams.first)
          VenueComment.delay.map_instagrams_to_hashes_and_convert(instagrams)
        end
        #set venue's last vc fields to latest instagram
        #venue.set_last_venue_comment_details(vc)        
      end
    end
  end

  def set_last_venue_comment_details(vc)
    if vc != nil
      if vc.class.name == "VenueComment"
        self.update_columns(venue_comment_id: vc.id)
        self.update_columns(venue_comment_instagram_id: vc.instagram_id)
        self.update_columns(venue_comment_created_at: vc.time_wrapper)
        self.update_columns(venue_comment_content_origin: vc.content_origin)
        self.update_columns(venue_comment_thirdparty_username: vc.thirdparty_username)
        self.update_columns(media_type: vc.media_type)
        self.update_columns(image_url_1: vc.image_url_1)
        self.update_columns(image_url_2: vc.image_url_2)
        self.update_columns(image_url_3: vc.image_url_3)
        self.update_columns(video_url_1: vc.video_url_1)
        self.update_columns(video_url_2: vc.video_url_2)
        self.update_columns(video_url_3: vc.video_url_3)
      else
        if vc.type == "video"
          video_url_1 = vc.videos.try(:low_bandwith).try(:url)
          video_url_2 = vc.videos.try(:low_resolution).try(:url)
          video_url_3 = vc.videos.try(:standard_resolution).try(:url)
        else
          video_url_1 = nil
          video_url_2 = nil
          video_url_3 = nil
        end
        self.update_columns(venue_comment_id: nil)
        self.update_columns(venue_comment_instagram_id: vc.id)
        self.update_columns(venue_comment_created_at: DateTime.strptime("#{vc.created_time}",'%s'))
        self.update_columns(venue_comment_content_origin: "instagram")
        self.update_columns(venue_comment_thirdparty_username: vc.user.username)
        self.update_columns(media_type: vc.type)
        self.update_columns(image_url_1: vc.images.try(:thumbnail).try(:url))
        self.update_columns(image_url_2: vc.images.try(:low_resolution).try(:url))
        self.update_columns(image_url_3: vc.images.try(:standard_resolution).try(:url))
        self.update_columns(video_url_1: video_url_1)
        self.update_columns(video_url_2: video_url_2)
        self.update_columns(video_url_3: video_url_3)
      end
    end
  end
  #----------------------------------------------------------------------------->


  #IV. Additional/Misc Functionalities ------------------------------------------->
  #determines the type of venue, ie, country, state, city, neighborhood, or just a regular establishment.
  def last_post_time
    if latest_posted_comment_time != nil
      (Time.now - latest_posted_comment_time)
    else
      nil
    end
  end

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

  def self.near_locations(lat, long)
    radius = 400.0 * 1/1000
    surroundings = Venue.within(radius.to_i, :units => :kms, :origin => [lat, long]).where("has_been_voted_at = TRUE AND is_address = FALSE").order('distance ASC limit 10')
    #Venue.within(Venue.meters_to_miles(meter_radius.to_i), :origin => [lat, long]).where("has_been_voted_at = TRUE AND is_address = FALSE").order('distance ASC limit 10')
  end

  def cord_to_city
    query = self.latitude.to_s + "," + self.longitude.to_s
    result = Geocoder.search(query).first 
    result_city = result.city || result.county
    result_city.slice!(" County")
    self.update_columns(city: result_city)
    return result_city
  end

  def Venue.reverse_geo_city_lookup(lat, long)
    query = lat.to_s + "," + long.to_s
    result = Geocoder.search(query).first 
    city = result.city
=begin    
    city = result.city || result.county
    if city == nil
      city = result.state
    end
    city.slice!(" County")
=end
  end

  def self.reverse_geo_country_lookup(lat, long)
    query = lat.to_s + "," + long.to_s
    result = Geocoder.search(query).first 
    country = result.country
  end

  def get_city_implicitly
    result = city || cord_to_city rescue nil
  end

  def self.miles_to_meters(miles)
    miles * 1609.34
  end

  def self.meters_to_miles(meter)
    meter * 0.000621371
  end

  def self.reset_venues
    Venue.update_all(rating: nil)
    Venue.update_all(r_up_votes: 1.0)
    Venue.update_all(r_down_votes: 1.0)
    Venue.update_all(color_rating: -1.0)
    VenueComment.where("content_origin = ?", "instagram").delete_all
    MetaData.delete_all
    LytSphere.delete_all
    LytitVote.where("user_id IS NULL").delete_all
  end

  def self.reset_venue_lyt_spheres
    target_venues = Venue.all
    for v in target_venues
      if v.latitude < 0 && v.longitude >= 0
        quadrant = "a"
      elsif v.latitude < 0 && v.longitude < 0
        quadrant = "b"
      elsif v.latitude >= 0 && v.longitude < 0
        quadrant = "c"
      else
        quadrant = "d"
      end
      new_l_sphere = quadrant+(v.latitude.round(1).abs).to_s+(v.longitude.round(1).abs).to_s
      v.update_columns(l_sphere: new_l_sphere)
    end
  end

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
  #------------------------------------------------------------------------------>

  #V. Twitter Functionality ----------------------------------------------------->
  def venue_twitter_tweets
    time_out_minutes = 5
    if self.last_twitter_pull_time == nil or (Time.now - self.last_twitter_pull_time > time_out_minutes.minutes)
      
      new_venue_tweets = self.update_tweets(true)

      total_venue_tweets = []
      if new_venue_tweets != nil
        total_venue_tweets << new_venue_tweets.sort_by{|tweet| Tweet.popularity_score_calculation(tweet.user.followers_count, tweet.retweet_count, tweet.favorite_count)}
      end
      total_venue_tweets << Tweet.where("venue_id = ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", id).order("timestamp DESC").order("popularity_score DESC")
      total_venue_tweets.flatten!.compact!
      return Kaminari.paginate_array(total_venue_tweets)
    else
      Tweet.where("venue_id = ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", id).order("timestamp DESC").order("popularity_score DESC")
    end
  end

  def self.cluster_twitter_tweets(cluster_lat, cluster_long, zoom_level, map_scale, venue_ids)    
    cluster = ClusterTracker.check_existence(cluster_lat, cluster_long, zoom_level)
    cluster_venue_ids = venue_ids.split(',').map(&:to_i)
    radius = map_scale.to_f/2.0 * 1/1000#Venue.meters_to_miles(map_scale.to_f/2.0)
    cluster_center_point = [cluster_lat, cluster_long]
    search_box = Geokit::Bounds.from_point_and_radius(cluster_center_point, radius, :units => :kms)

    time_out_minutes = 3
    if cluster.last_twitter_pull_time == nil or cluster.last_twitter_pull_time > Time.now - time_out_minutes.minutes
      cluster.update_columns(last_twitter_pull_time: Time.now)
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = '286I5Eu8LD64ApZyIZyftpXW2'
        config.consumer_secret     = '4bdQzIWp18JuHGcKJkTKSl4Oq440ETA636ox7f5oT0eqnSKxBv'
        config.access_token        = '2846465294-QPuUihpQp5FjOPlKAYanUBgRXhe3EWAUJMqLw0q'
        config.access_token_secret = 'mjYo0LoUnbKT4XYhyNfgH4n0xlr2GCoxBZzYyTPfuPGwk'
      end
      
      location_query = ""
      tag_query = ""

      underlying_venues = Venue.where("id IN (?)", cluster_venue_ids).order("popularity_rank DESC LIMIT 4").select("name")
      underlying_venues.each{|v| location_query+=(v.name+" OR ")}
      tags = MetaData.cluster_top_meta_tags(venue_ids)
      tags.each{|tag| tag_query+=(tag.first.last+" OR ") if tag.first.last != nil || tag.first.last != ""}

      location_query.chomp!(" OR ") 
      tag_query.chomp!(" OR ") 

      location_tweets = client.search(location_query+" -rt", result_type: "recent", geo_code: "#{cluster_lat},#{cluster_long},#{radius}km").take(20).collect.to_a rescue nil
      tag_query_tweets = client.search(tag_query+" -rt", result_type: "recent", geo_code: "#{cluster_lat},#{cluster_long},#{radius}km").take(20).collect.to_a rescue nil
      new_cluster_tweets = []
      total_cluster_tweets = []

      if location_tweets != nil 
        new_cluster_tweets << location_tweets
      end

      if tag_query_tweets != nil
        new_cluster_tweets << tag_query_tweets
      end

      if location_tweets != nil || tag_query_tweets != nil
        new_cluster_tweets.flatten!.compact!
        new_cluster_tweets.sort_by!{|tweet| Tweet.popularity_score_calculation(tweet.user.followers_count, tweet.retweet_count, tweet.favorite_count)}      
        total_cluster_tweets << new_cluster_tweets
      end

      total_cluster_tweets << Tweet.in_bounds(search_box).where("associated_zoomlevel >= ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", zoom_level).order("timestamp DESC").order("popularity_score DESC")

      #Tweet.where("venue_id IN (?) OR (ACOS(least(1,COS(RADIANS(#{cluster_lat}))*COS(RADIANS(#{cluster_long}))*COS(RADIANS(latitude))*COS(RADIANS(longitude))+COS(RADIANS(#{cluster_lat}))*SIN(RADIANS(#{cluster_long}))*COS(RADIANS(latitude))*SIN(RADIANS(longitude))+SIN(RADIANS(#{cluster_lat}))*SIN(RADIANS(latitude))))*6376.77271) 
      #    <= #{radius} AND associated_zoomlevel >= ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", cluster_venue_ids, zoom_level).order("timestamp DESC").order("popularity_score DESC")
      total_cluster_tweets.flatten!.compact!

      if new_cluster_tweets.length > 0
        Tweet.delay.bulk_conversion(new_cluster_tweets, nil, cluster_lat, cluster_long, zoom_level, map_scale)
        #new_cluster_tweets.each{|tweet| Tweet.delay.create!(:twitter_id => tweet.id, :tweet_text => tweet.text, :image_url_1 => Tweet.implicit_image_url_1(tweet), :image_url_2 => Tweet.implicit_image_url_2(tweet), :image_url_3 => Tweet.implicit_image_url_3(tweet), :author_id => tweet.user.id, :handle => tweet.user.screen_name, :author_name => tweet.user.name, :author_avatar => tweet.user.profile_image_url.to_s, :timestamp => tweet.created_at, :from_cluster => true, :associated_zoomlevel => zoom_level, :latitude => cluster_lat, :longitude => cluster_long, :popularity_score => Tweet.popularity_score_calculation(tweet.user.followers_count, tweet.retweet_count, tweet.favorite_count))}
      end

      return Kaminari.paginate_array(total_cluster_tweets)
    else
      Tweet.in_bounds(search_box).where("associated_zoomlevel >= ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", zoom_level).order("timestamp DESC").order("popularity_score DESC")
      #Tweet.where("venue_id IN (?) OR (ACOS(least(1,COS(RADIANS(#{cluster_lat}))*COS(RADIANS(#{cluster_long}))*COS(RADIANS(latitude))*COS(RADIANS(longitude))+COS(RADIANS(#{cluster_lat}))*SIN(RADIANS(#{cluster_long}))*COS(RADIANS(latitude))*SIN(RADIANS(longitude))+SIN(RADIANS(#{cluster_lat}))*SIN(RADIANS(latitude))))*6376.77271) 
      #    <= #{radius} AND associated_zoomlevel >= ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", cluster_venue_ids, zoom_level).order("timestamp DESC").order("popularity_score DESC")
    end
  end

  def update_tweets(delay_conversion)
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = '286I5Eu8LD64ApZyIZyftpXW2'
        config.consumer_secret     = '4bdQzIWp18JuHGcKJkTKSl4Oq440ETA636ox7f5oT0eqnSKxBv'
        config.access_token        = '2846465294-QPuUihpQp5FjOPlKAYanUBgRXhe3EWAUJMqLw0q'
        config.access_token_secret = 'mjYo0LoUnbKT4XYhyNfgH4n0xlr2GCoxBZzYyTPfuPGwk'
      end

      radius = 0.25 #Venue.meters_to_miles(100)
      #query = ""
      #top_tags = self.meta_datas.order("relevance_score DESC LIMIT 5")
      #top_tags.each{|tag| query+=(tag.meta+" OR ") if tag.meta != nil || tag.meta != ""}
      #query+=(" OR "+self.name)
      query = self.name

      last_tweet_id = Tweet.where("venue_id = ?", self.id).order("twitter_id desc").first.try(:twitter_id)
      #begin
        if last_tweet_id != nil
          new_venue_tweets = client.search(query+" -rt", result_type: "recent", geo_code: "#{latitude},#{longitude},#{radius}km", since_id: "#{last_tweet_id}").take(20).collect.to_a rescue []
        else
          new_venue_tweets = client.search(query+" -rt", result_type: "recent", geo_code: "#{latitude},#{longitude},#{radius}km").take(20).collect.to_a rescue []
        end
        self.update_columns(last_twitter_pull_time: Time.now)

        if new_venue_tweets.length > 0
          if delay_conversion == true
            Tweet.delay.bulk_conversion(new_venue_tweets, self, nil, nil, nil, nil)
          else
            Tweet.bulk_conversion(new_venue_tweets, self, nil, nil, nil, nil)
          end
          #new_venue_tweets.each{|tweet| Tweet.delay.create!(:twitter_id => tweet.id, :tweet_text => tweet.text, :image_url_1 => Tweet.implicit_image_url_1(tweet), :image_url_2 => Tweet.implicit_image_url_2(tweet), :image_url_3 => Tweet.implicit_image_url_3(tweet), :author_id => tweet.user.id, :handle => tweet.user.screen_name, :author_name => tweet.user.name, :author_avatar => tweet.user.profile_image_url.to_s, :timestamp => tweet.created_at, :from_cluster => false, :venue_id => self.id, :popularity_score => Tweet.popularity_score_calculation(tweet.user.followers_count, tweet.retweet_count, tweet.favorite_count))}
        end
        new_venue_tweets
      #rescue
      #  puts "TWEET ERROR OCCURRED"
      #  return nil
      #end
  end

  def self.surrounding_twitter_tweets(user_lat, user_long, venue_ids)
    surrounding_venue_ids = venue_ids.split(',').map(&:to_i) rescue []
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = '286I5Eu8LD64ApZyIZyftpXW2'
      config.consumer_secret     = '4bdQzIWp18JuHGcKJkTKSl4Oq440ETA636ox7f5oT0eqnSKxBv'
      config.access_token        = '2846465294-QPuUihpQp5FjOPlKAYanUBgRXhe3EWAUJMqLw0q'
      config.access_token_secret = 'mjYo0LoUnbKT4XYhyNfgH4n0xlr2GCoxBZzYyTPfuPGwk'
    end
    surrounding_tweets = []
    radius = 200 #Venue.meters_to_miles(200)
    
    if surrounding_venue_ids.count > 0
      location_query = ""
      tag_query = ""
      
      underlying_venues = Venue.where("id IN (?)", surrounding_venue_ids).order("popularity_rank DESC LIMIT 4").select("name")
      underlying_venues.each{|v| location_query+=(v.name+" OR ")}
      tags = MetaData.cluster_top_meta_tags(venue_ids)
      tags.each{|tag| tag_query+=(tag.first.last+" OR ") if tag.first.last != nil || tag.first.last != ""}
      
      location_query.chomp!(" OR ") 
      tag_query.chomp!(" OR ") 

      location_tweets = client.search(location_query+" -rt", result_type: "recent", geo_code: "#{user_lat},#{user_long},#{radius}mi").take(20).collect.to_a
      tag_query_tweets = client.search(tag_query+" -rt", result_type: "recent", geo_code: "#{user_lat},#{user_long},#{radius}mi").take(20).collect.to_a
      
      surrounding_tweets << location_tweets
      surrounding_tweets << tag_query_tweets
      surrounding_tweets.flatten!.compact!
    else
      query = user_lat.to_s + "," + user_long.to_s
      result = Geocoder.search(query).first 
      result_city = result.city || result.county
      result_city.slice!(" County")

      user_city = result_city
      user_state = result.state
      user_country = result.country

      vague_query = user_city+" OR "+user_state+" OR "+user_country
      surrounding_tweets = client.search(vague_query+" -rt", result_type: "recent", geo_code: "#{user_lat},#{user_long},#{radius}mi").take(20).collect.to_a
    end
    
    if surrounding_tweets.length > 0
      Tweet.delay.bulk_conversion(surrounding_tweets, nil, user_lat, user_long, 18, nil)
      #surrounding_tweets.each{|tweet| Tweet.delay.create!(:twitter_id => tweet.id, :tweet_text => tweet.text, :image_url_1 => Tweet.implicit_image_url_1(tweet), :image_url_2 => Tweet.implicit_image_url_2(tweet), :image_url_3 => Tweet.implicit_image_url_3(tweet), :author_id => tweet.user.id, :handle => tweet.user.screen_name, :author_name => tweet.user.name, :author_avatar => tweet.user.profile_image_url.to_s, :timestamp => tweet.created_at, :from_cluster => true, :latitude => user_lat, :longitude => user_long, :popularity_score => Tweet.popularity_score_calculation(tweet.user.followers_count, tweet.retweet_count, tweet.favorite_count))}
    end

    return surrounding_tweets.sort_by{|tweet| Tweet.popularity_score_calculation(tweet.user.followers_count, tweet.retweet_count, tweet.favorite_count)}  
  end

  def set_last_tweet_details(tweet)
    self.update_columns(lytit_tweet_id: tweet.id)
    self.update_columns(twitter_id: tweet.twitter_id)
    self.update_columns(tweet_text: tweet.tweet_text)
    self.update_columns(tweet_created_at: tweet.timestamp)
    self.update_columns(tweet_author_name: tweet.author_name)
    self.update_columns(tweet_author_id: tweet.author_id)
    self.update_columns(tweet_author_avatar_url: tweet.author_name)
    self.update_columns(tweet_handle: tweet.handle)
  end

=begin
  def self.surrounding_feed(lat, long, surrounding_venue_ids)
    if surrounding_venue_ids != nil and surrounding_venue_ids.length > 0
      meter_radius = 100
      surrounding_instagrams = (Instagram.media_search(lat, long, :distance => meter_radius, :count => 20, :min_timestamp => (Time.now-24.hours).to_time.to_i)).sort_by{|inst| Venue.spherecial_distance_between_points(lat, long, inst.location.latitude, inst.location.longitude)}
      surrounding_instagrams.map!(&:to_hash)

      if surrounding_instagrams.count >= 20
        surrounding_feed = surrounding_instagrams
      else
        inst_lytit_posts = []
        inst_lytit_posts << surrounding_instagrams
        inst_lytit_posts << VenueComment.joins(:venue).where("venues.id IN (#{surrounding_venue_ids})").order("rating DESC").order("name ASC").order("venue_comments.time_wrapper DESC")
        inst_lytit_posts.flatten!
        surrounding_feed = inst_lytit_posts
      end

    else
      meter_radius = 5000
      surrounding_instagrams = (Instagram.media_search(lat, long, :distance => meter_radius, :count => 100, :min_timestamp => (Time.now-24.hours).to_time.to_i)).sort_by{|inst| Geocoder::Calculations.distance_between([lat.to_f, long.to_f], [inst.location.latitude.to_f, inst.location.longitude.to_f], :units => :km)}
      
      surrounding_instagrams.map!(&:to_hash)
      surrounding_feed = surrounding_instagrams
    end


    #converting to lytit venue comments
    VenueComment.delay.convert_bulk_instagrams_to_vcs(surrounding_instagrams, nil)

    return surrounding_feed
  end
=end 

  def self.spherecial_distance_between_points(lat_1, long_1, lat_2, long_2)
    result = Geocoder::Calculations.distance_between([lat_1, long_1], [lat_2, long_2], :units => :km)
    if result >= 0.0
      result
    else
      1000.0
    end
  end

  #VI. LYT Algorithm Related Calculations and Calibrations ------------------------->
  def v_up_votes
    LytitVote.where("venue_id = ? AND value = ? AND created_at >= ?", self.id, 1, Time.now.beginning_of_day)
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
    #puts "bar position = #{LytitBar.instance.position}"
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

  def update_r_up_votes(time_wrapped_posting_time)
    if time_wrapped_posting_time != nil && latest_posted_comment_time != nil
      new_r_up_vote_count = ((self.r_up_votes-1.0) * 2**((-(time_wrapped_posting_time.to_datetime - latest_posted_comment_time.to_datetime)/60.0) / (LytitConstants.vote_half_life_h))+2.0).round(4)
    else
      new_r_up_vote_count = self.r_up_votes + 1.0
    end
    
    self.update_columns(r_up_votes: new_r_up_vote_count)
  end

  def update_rating()
    new_r_up_vote_count = ((self.r_up_votes-1.0) * 2**((-(Time.now - latest_posted_comment_time.to_datetime)/60.0) / (LytitConstants.vote_half_life_h))).round(4)+1.0
    self.update_columns(r_up_votes: new_r_up_vote_count)

    y = (1.0 / (1 + LytitConstants.rating_loss_l)).round(4)

    a = self.r_up_votes >= 1.0 ? r_up_votes : 1.0
    b = 1.0

    if (a - 1.0).round(4) == 0.0
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
        #update the popularity rank as well if the last rating update was over 5 minutes ago
        if latest_rating_update_time != nil and latest_rating_update_time < Time.now - 5.minutes
          update_popularity_rank
        end

        update_columns(latest_rating_update_time: Time.now)
      else
        puts "Could not calculate rating. Status: #{$?.to_i}"
      end
    end
  end

  def is_visible?
    visible = true
    if self.rating == nil or self.rating.round(1) == 0.0
      visible = false
    end

    if city == "New York" && (Time.now - latest_posted_comment_time)/60.0 >= (LytitConstants.threshold_to_venue_be_shown_on_map-15.0)
      visible = false
    else
      if city != "New York" && (Time.now - latest_posted_comment_time)/60.0 >= LytitConstants.threshold_to_venue_be_shown_on_map
        visible = false
      end
    end

    if visible == false
      self.update_columns(rating: nil)
      self.update_columns(r_up_votes: 1.0)
      self.update_columns(r_down_votes: 1.0)
      self.update_columns(color_rating: -1.0)
      self.update_columns(trend_position: nil)
      self.update_columns(popularity_rank: 0.0)
      self.lyt_spheres.delete_all
    end

    return visible
  end

  def reset_r_vector
    self.r_up_votes = 1 + get_k
    self.r_down_votes = 1
    save
  end

  #priming factor that used to be calculted from historical average rating of a place
  def get_k
    0
  end  

  def set_top_tags
    top_tags = self.meta_datas.order("relevance_score DESC").limit(5)
    self.update_columns(tag_1: top_tags[0].try(:meta))
    self.update_columns(tag_2: top_tags[1].try(:meta))
    self.update_columns(tag_3: top_tags[2].try(:meta))
    self.update_columns(tag_4: top_tags[3].try(:meta))
    self.update_columns(tag_5: top_tags[4].try(:meta))
  end

  def Venue.cleanup_and_calibration
    active_venue_ids = "SELECT venue_id FROM lyt_spheres"
    stale_venue_ids = "SELECT id FROM venues WHERE id NOT IN (#{active_venue_ids}) AND color_rating > -1.0"
    Venue.where("id IN (#{stale_venue_ids})").update_all(rating: nil)
    Venue.where("id IN (#{stale_venue_ids})").update_all(color_rating: -1.0)
    Venue.where("id IN (#{stale_venue_ids})").update_all(popularity_rank: 0.0)

  end

  def Venue.cleanup_venues_for_crackle    
    feed_venue_ids = "SELECT venue_id FROM feed_venues"
    Venue.joins(:feed_venues).where("verified IS FALSE").update_all(verified: true)
    Venue.where("address IS NOT NULL AND verified IS FALSE").update_all(verified: true)
    false_venues = Venue.where("verified IS FALSE").pluck(:id)
    VenueComment.where("venue_id IN (?)", false_venues).delete_all
    MetaData.where("venue_id IN (?)", false_venues).delete_all
    LytitVote.where("venue_id IN (?)", false_venues).delete_all
    Tweet.where("venue_id IN (?)", false_venues).delete_all
    LytSphere.where("venue_id IN (?)", false_venues).delete_all
    VenuePageView.where("venue_id IN (?)", false_venues).delete_all
    Activity.where("venue_id IN (?)", false_venues).delete_all
  end

  def Venue.timezone_and_vortex_calibration
    ivs = InstagramVortex.all
    for iv in ivs
      iv.set_timezone_offsets
      center_point = [iv.latitude, iv.longitude]
      proximity_box = Geokit::Bounds.from_point_and_radius(center_point, 10, :units => :kms)
      nearby_venues = Venue.in_bounds(proximity_box)
      nearby_venues.update_all(instagram_vortex_id: iv.id)
      nearby_venues.update_all(time_zone: iv.time_zone)
      nearby_venues.update_all(time_zone_offset: iv.time_zone_offset)
    end
  end

  #----------------------------------------------------------------------------->
  #VII.

  private 

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

  def Venue.linked_user_lists(v_id, u_id)
    user_list_ids = "SELECT feed_id FROM feed_users WHERE user_id = #{u_id}"
    linked_feed_ids = "SELECT feed_id FROM feed_venues WHERE venue_id = #{v_id} AND feed_id IN (#{user_list_ids})"
    Feed.where("id IN (#{linked_feed_ids})") 
  end

end
