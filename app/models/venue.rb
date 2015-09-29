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

  belongs_to :user

  accepts_nested_attributes_for :venue_messages, allow_destroy: true, reject_if: proc { |attributes| attributes['message'].blank? or attributes['position'].blank? }

  MILE_RADIUS = 2

  scope :visible, -> { joins(:lytit_votes).where('lytit_votes.created_at > ?', Time.now - LytitConstants.threshold_to_venue_be_shown_on_map.minutes) }

  #I. Search------------------------------------------------------->
  def self.direct_fetch(query, position_lat, position_long, ne_lat, ne_long, sw_lat, sw_long)
    name_search = Venue.where("LOWER(name) LIKE ?", query.downcase+"%").order("(ACOS(least(1,COS(RADIANS(#{position_lat}))*COS(RADIANS(#{position_long}))*COS(RADIANS(venues.latitude))*COS(RADIANS(venues.longitude))+COS(RADIANS(#{position_lat}))*SIN(RADIANS(#{position_long}))*COS(RADIANS(venues.latitude))*SIN(RADIANS(venues.longitude))+SIN(RADIANS(#{position_lat}))*SIN(RADIANS(venues.latitude))))*3963.1899999999996) ASC LIMIT 10")

    if name_search == nil
      in_view_search = Venue.where("latitude > ? AND latitude < ? AND longitude > ? AND longitude < ? AND LOWER(name) LIKE ?", sw_lat, ne_lat, sw_long, ne_long, "%"+query.downcase+"%").limit(10)
      return in_view_search
    else
      return name_search
    end

  end

  #LYTiT database venue match-search
  def self.fetch(vname, vaddress, vcity, vstate, vcountry, vpostal_code, vphone, vlatitude, vlongitude, pin_drop)
    require 'fuzzystringmatch'
    jarow = FuzzyStringMatch::JaroWinkler.create( :native ) 
    if vname == nil && vcountry == nil
      return
    end

    direct_search = Venue.where("latitude = ? AND longitude = ?", vlatitude, vlongitude)
    result = nil
    if direct_search.count != 0
      if direct_search.count > 1
        best_match = nil
        best_match_score = 0.75
        for entry in direct_search
            text_comparison_score = (p jarow.getDistance(entry.name, vname))
            if text_comparison_score > best_match_score
              best_match = entry
              best_match_score = text_comparison_score 
            end
        end
        if best_match != nil
          result = best_match
        end
      else
          if (p jarow.getDistance(direct_search.first.name, vname)) >= 0.8
            result = direct_search.first
          end
      end
    end

    if result == nil
      name_search = Venue.where("LOWER(name) LIKE ? AND ABS(#{vlatitude} - latitude) <= 0.5 AND ABS(#{vlongitude} - longitude) <= 0.5", '%' + vname.to_s.downcase + '%')
      if name_search.count != 0
        if name_search.count > 1
          best_match = nil
          best_match_score = 0.75
          for entry in name_search
              text_comparison_score = (p jarow.getDistance(entry.name, vname))
              if text_comparison_score > best_match_score
                best_match = entry
                best_match_score = text_comparison_score 
              end
          end
          if best_match != nil
            result = best_match
          end
        else
            if (p jarow.getDistance(name_search.first.name, vname)) >= 0.8
              result = name_search.first
            end
        end
      end
    end

    if result != nil
      puts "A direct match has been found - name:#{result.name}, id:#{result.id} "
      lookup = result
    else
      #We need to determine the type of search being conducted whether it is venue specific or geographic
      if vaddress == nil
        if vcity != nil #city search
          radius = 3000
          boundries = bounding_box(radius, vlatitude, vlongitude)
          venues = Venue.where("latitude > ? AND latitude < ? AND longitude > ? AND longitude < ? AND 
            address IS NULL AND name = ? OR name = ?", boundries["min_lat"], boundries["max_lat"], boundries["min_long"], boundries["max_long"], vcity, vname)
        end

        if vstate != nil && vcity == nil #state search
          radius = 30000
          boundries = bounding_box(radius, vlatitude, vlongitude)
          venues = Venue.where("latitude > ? AND latitude < ? AND longitude > ? AND longitude < ? AND 
            address IS NULL AND city IS NULL AND name = ? OR name = ?", boundries["min_lat"], boundries["max_lat"], boundries["min_long"], boundries["max_long"], vstate, vname)
        end

        if (vcountry != nil && vstate == nil ) && vcity == nil #country search
          radius = 300000
          boundries = bounding_box(radius, vlatitude, vlongitude)
          venues = Venue.where("latitude > ? AND latitude < ? AND longitude > ? AND longitude < ? AND 
            address IS NULL AND city IS NULL AND state IS NULL AND name = ? OR name = ?", boundries["min_lat"], boundries["max_lat"], boundries["min_long"], boundries["max_long"], vcountry, vname)
        end
      else #venue search 
        radius = 250
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

      #Iterate through venues in target area to find a string match by name. If venues were selected by name search we consider proximity as a determing factor for a match as well.
      for venue in venues
        if venue.name.downcase == vname.downcase #Is there a direct string match?
          lookup = venue
          break
        end

        if ( ((venue.name.downcase).include?(vname.downcase) && vname.length.to_f/venue.name.length.to_f > 0.5) || ((vname.downcase).include?(venue.name.downcase) && venue.name.length.to_f/vname.length.to_f > 0.5) ) && (specific_address == false) # --&& (venue.address == vaddress)-- #Are they substrings?
          lookup = venue
          break
        end

        if (p jarow.getDistance(venue.name.downcase.gsub("the", "").gsub(" a ", "").gsub("café", "").gsub("cafe", "").gsub("restaurant", "").gsub("club", "").gsub("downtown", "").gsub("updtown", "").gsub("park", "").gsub("national", "").gsub(" ", ""), vname.downcase.downcase.gsub("the", "").gsub(" a ", "").gsub("café", "").gsub("cafe", "").gsub("restaurant", "").gsub("club", "").gsub("downtown", "").gsub("updtown", "").gsub("park", "").gsub("national", "").gsub(" ", "")) >= 0.8) && (specific_address == false)
          lookup = venue
        end

      end
    end

    if lookup != nil
      lookup.postal_code = vpostal_code.to_s #We always set the postal code no matter what because we use it as a flag to determine if a venue page should be displayed
      lookup.save
      if lookup.city == nil || lookup.state == nil #Add venue details if they are not present
        
        part1 = [vaddress, vcity].compact.join(', ')
        part2 = [part1, vstate].compact.join(', ')
        part3 = [part2, vpostal_code].compact.join(' ')
        part4 = [part3, vcountry].compact.join(', ')

        
        lookup.update_columns(formatted_address: part4) rescue lookup.update_columns(formatted_address: nil)
        lookup.update_columns(city: vcity) rescue lookup.update_columns(city: nil)
        lookup.update_columns(state: vstate) rescue lookup.update_columns(state: nil)
        lookup.update_columns(country: vcountry) rescue lookup.update_columns(country: nil)

        lookup.phone_number = formatTelephone(vphone)
        lookup.save
      end
      if lookup.l_sphere == nil
        if lookup.latitude < 0 && lookup.longitude >= 0
          quadrant = "a"
        elsif lookup.latitude < 0 && lookup.longitude < 0
          quadrant = "b"
        elsif lookup.latitude >= 0 && lookup.longitude < 0
          quadrant = "c"
        else
          quadrant = "d"
        end
        lookup.l_sphere = quadrant+(lookup.latitude.round(1).abs).to_s+(lookup.longitude.round(1).abs).to_s
        lookup.save
      end
      if lookup.time_zone == nil #Add timezone of venue if not present
        Timezone::Configure.begin do |c|
          c.username = 'LYTiT'
        end
        timezone = Timezone::Zone.new :latlon => [vlatitude, vlongitude] rescue nil
        lookup.time_zone = timezone.active_support_time_zone rescue nil
      end
      if lookup.time_zone_offset == nil
        lookup.time_zone_offset = Time.now.in_time_zone(lookup.time_zone).utc_offset/3600.0  rescue nil
      end
      
      #if lookup.name != vname
      #  lookup.name = vname
      #end

      if lookup.latitude != vlatitude
        lookup.latitude = vlatitude
      end

      if lookup.longitude != vlongitude
        lookup.longitude = vlongitude
      end

      #if lookup.address != vaddress
      #  lookup.update_columns(address: vaddress) rescue lookup.address = "N/A"
      #end

      lookup.save

      if lookup.instagram_location_id == nil && pin_drop != 1#Add instagram location id
        lookup.set_instagram_location_id(100)
      end
      return lookup
    else
      Timezone::Configure.begin do |c|
        c.username = 'LYTiT'
      end
      timezone = Timezone::Zone.new :latlon => [vlatitude, vlongitude] rescue nil

      venue = Venue.new
      venue.name = vname
      venue.latitude = vlatitude
      venue.longitude = vlongitude
      venue.save

      venue.update_columns(address: vaddress) rescue venue.update_columns(address: nil)
      part1 = [vaddress, vcity].compact.join(', ')
      part2 = [part1, vstate].compact.join(', ')
      part3 = [part2, vpostal_code].compact.join(' ')
      part4 = [part3, vcountry].compact.join(', ')

      venue.update_columns(formatted_address: part4) rescue venue.update_columns(formatted_address: nil)
      venue.update_columns(city: vcity) rescue venue.update_columns(city: nil)
      venue.update_columns(state: vstate) rescue venue.update_columns(state: nil)
      venue.update_columns(country: vcountry) rescue venue.update_columns(country: nil)
  
      venue.postal_code = vpostal_code.to_s
      venue.phone_number = formatTelephone(vphone)

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

      venue.time_zone = timezone.active_support_time_zone rescue nil
      venue.time_zone_offset = Time.now.in_time_zone(timezone.active_support_time_zone).utc_offset/3600.0 rescue nil
      venue.fetched_at = Time.now

      if vaddress != nil && vname != nil
        if vaddress.gsub(" ","").gsub(",", "") == vname.gsub(" ","").gsub(",", "")
          venue.is_address = true
        end
      end

      venue.save
      venue.set_instagram_location_id(100)
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
  #------------------------------------------------------------------------>


  #II. Venue Popularity Ranking Functionality --------------------------------->
  def view(user_id)
    view = VenuePageView.new(:user_id => user_id, :venue_id => self.id, :venue_lyt_sphere =>  self.l_sphere)
    view.save
  end

  def account_page_view
    view_half_life = 120.0 #minutes
    latest_page_view_time_wrapper = latest_page_view_time || Time.now
    new_page_view_count = (self.page_views * 2 ** ((-(Time.now - latest_page_view_time_wrapper)/60.0) / (view_half_life))).round(4)+1.0

    self.update_columns(page_views: new_page_view_count)
    self.update_columns(latest_page_view_time: Time.now)
  end

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

  def self.trending_venues
    key = "trending_venues"
    Rails.cache.fetch key, expires_in: 3.minutes do
      Venue.all.joins(:venue_comments).where("venue_comments.time_wrapper > ?", Time.now-1.day).order("popularity_rank desc limit 10")
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
  def self.name_is_proper?(vname) 
    emoji_and_symbols = ["💗", "❤", "✌", "😊", "😀", "😁", "😂", "😃", "😄", "😅", "😆", "😇", "😈", "👿", "😉", "😊", "☺️", "😋", "😌", "😍", "😎", "😏", "😐", "😑", "😒", "😓", "😔", "😕", "😖", "😗", "😘", "😙", "😚", "😛", "😜", "😝", "😞", "😟", "😠", "😡", "😢", "😣", "😤", "😥", "😦", "😧", "😨", "😩", "😪", "😫", "😬", "😭", "😮", "😯", "😰", "😱", "😲", "😳", "😴", "😵", "😶", "😷", "🙁", "🙂", "😸", "😹", "😺", "😻", "😼", "😽", "😾", "😿", "🙀", "👣", "👤", "👥", "👦", "👧", "👨", "👩", "👨‍👩‍👦", "👨‍👩‍👧", "👪", "👨‍👩‍👦‍👦", "👨‍👩‍👧‍👧", "👩‍👩‍👦", "👩‍👩‍👧", "👩‍👩‍👧‍👦", "👩‍👩‍👦‍👦", "👩‍👩‍👧‍👧", "👨‍👨‍👦", "👨‍👨‍👧", "👨‍👨‍👧‍👦", "👨‍👨‍👦‍👦", "👨‍👨‍👧‍👧", "👫", "👬", "👭", "👮", "👯", "👰", "👱", "👲", "👳", "👴", "👵", "👶", "👷", "👸", "💂", "👼", "🎅", "👻", "👹", "👺", "💩", "💀", "👽", "👾", "🙇", "💁", "🙅", "🙆", "🙋", "🙎", "🙍", "💆", "💇", "💑", "👩‍❤️‍👩", "👨‍❤️‍👨", "💏", "👩‍❤️‍💋‍👩", "👨‍❤️‍💋‍👨", "💅", "👂", "👀", "👃", "👄", "💋", "👅👋", "👍", "👎", "☝️", "👆", "👇", "👈", "👉", "👌", "✌️", "👊", "✊", "✋", "💪", "👐", "🙌", "👏", "🙏", "🖐", "🖕", "🖖", "👦\u{1F3FB}", "👧\u{1F3FB}", "👨\u{1F3FB}", "👩\u{1F3FB}", "👮\u{1F3FB}", "👰\u{1F3FB}", "👱\u{1F3FB}", "👲\u{1F3FB}", "👳\u{1F3FB}", "👴\u{1F3FB}", "👵\u{1F3FB}", "👶\u{1F3FB}", "👷\u{1F3FB}", "👸\u{1F3FB}", "💂\u{1F3FB}", "👼\u{1F3FB}", "🎅\u{1F3FB}", "🙇\u{1F3FB}", "💁\u{1F3FB}", "🙅\u{1F3FB}", "🙆\u{1F3FB}", "🙋\u{1F3FB}", "🙎\u{1F3FB}", "🙍\u{1F3FB}", "💆\u{1F3FB}", "💇\u{1F3FB}", "💅\u{1F3FB}", "👂\u{1F3FB}", "👃\u{1F3FB}", "👋\u{1F3FB}", "👍\u{1F3FB}", "👎\u{1F3FB}", "☝\u{1F3FB}", "👆\u{1F3FB}", "👇\u{1F3FB}", "👈\u{1F3FB}", "👉\u{1F3FB}", "👌\u{1F3FB}", "✌\u{1F3FB}", "👊\u{1F3FB}", "✊\u{1F3FB}", "✋\u{1F3FB}", "💪\u{1F3FB}", "👐\u{1F3FB}", "🙌\u{1F3FB}", "👏\u{1F3FB}", "🙏\u{1F3FB}", "🖐\u{1F3FB}", "🖕\u{1F3FB}", "🖖\u{1F3FB}", "👦\u{1F3FC}", "👧\u{1F3FC}", "👨\u{1F3FC}", "👩\u{1F3FC}", "👮\u{1F3FC}", "👰\u{1F3FC}", "👱\u{1F3FC}", "👲\u{1F3FC}", "👳\u{1F3FC}", "👴\u{1F3FC}", "👵\u{1F3FC}", "👶\u{1F3FC}", "👷\u{1F3FC}", "👸\u{1F3FC}", "💂\u{1F3FC}", "👼\u{1F3FC}", "🎅\u{1F3FC}", "🙇\u{1F3FC}", "💁\u{1F3FC}", "🙅\u{1F3FC}", "🙆\u{1F3FC}", "🙋\u{1F3FC}", "🙎\u{1F3FC}", "🙍\u{1F3FC}", "💆\u{1F3FC}", "💇\u{1F3FC}", "💅\u{1F3FC}", "👂\u{1F3FC}", "👃\u{1F3FC}", "👋\u{1F3FC}", "👍\u{1F3FC}", "👎\u{1F3FC}", "☝\u{1F3FC}", "👆\u{1F3FC}", "👇\u{1F3FC}", "👈\u{1F3FC}", "👉\u{1F3FC}", "👌\u{1F3FC}", "✌\u{1F3FC}", "👊\u{1F3FC}", "✊\u{1F3FC}", "✋\u{1F3FC}", "💪\u{1F3FC}", "👐\u{1F3FC}", "🙌\u{1F3FC}", "👏\u{1F3FC}", "🙏\u{1F3FC}", "🖐\u{1F3FC}", "🖕\u{1F3FC}", "🖖\u{1F3FC}", "👦\u{1F3FD}", "👧\u{1F3FD}", "👨\u{1F3FD}", "👩\u{1F3FD}", "👮\u{1F3FD}", "👰\u{1F3FD}", "👱\u{1F3FD}", "👲\u{1F3FD}", "👳\u{1F3FD}", "👴\u{1F3FD}", "👵\u{1F3FD}", "👶\u{1F3FD}", "👷\u{1F3FD}", "👸\u{1F3FD}", "💂\u{1F3FD}", "👼\u{1F3FD}", "🎅\u{1F3FD}", "🙇\u{1F3FD}", "💁\u{1F3FD}", "🙅\u{1F3FD}", "🙆\u{1F3FD}", "🙋\u{1F3FD}", "🙎\u{1F3FD}", "🙍\u{1F3FD}", "💆\u{1F3FD}", "💇\u{1F3FD}", "💅\u{1F3FD}", "👂\u{1F3FD}", "👃\u{1F3FD}", "👋\u{1F3FD}", "👍\u{1F3FD}", "👎\u{1F3FD}", "☝\u{1F3FD}", "👆\u{1F3FD}", "👇\u{1F3FD}", "👈\u{1F3FD}", "👉\u{1F3FD}", "👌\u{1F3FD}", "✌\u{1F3FD}", "👊\u{1F3FD}", "✊\u{1F3FD}", "✋\u{1F3FD}", "💪\u{1F3FD}", "👐\u{1F3FD}", "🙌\u{1F3FD}", "👏\u{1F3FD}", "🙏\u{1F3FD}", "🖐\u{1F3FD}", "🖕\u{1F3FD}", "🖖\u{1F3FD}", "👦\u{1F3FE}", "👧\u{1F3FE}", "👨\u{1F3FE}", "👩\u{1F3FE}", "👮\u{1F3FE}", "👰\u{1F3FE}", "👱\u{1F3FE}", "👲\u{1F3FE}", "👳\u{1F3FE}", "👴\u{1F3FE}", "👵\u{1F3FE}", "👶\u{1F3FE}", "👷\u{1F3FE}", "👸\u{1F3FE}", "💂\u{1F3FE}", "👼\u{1F3FE}", "🎅\u{1F3FE}", "🙇\u{1F3FE}", "💁\u{1F3FE}", "🙅\u{1F3FE}", "🙆\u{1F3FE}", "🙋\u{1F3FE}", "🙎\u{1F3FE}", "🙍\u{1F3FE}", "💆\u{1F3FE}", "💇\u{1F3FE}", "💅\u{1F3FE}", "👂\u{1F3FE}", "👃\u{1F3FE}", "👋\u{1F3FE}", "👍\u{1F3FE}", "👎\u{1F3FE}", "☝\u{1F3FE}", "👆\u{1F3FE}", "👇\u{1F3FE}", "👈\u{1F3FE}", "👉\u{1F3FE}", "👌\u{1F3FE}", "✌\u{1F3FE}", "👊\u{1F3FE}", "✊\u{1F3FE}", "✋\u{1F3FE}", "💪\u{1F3FE}", "👐\u{1F3FE}", "🙌\u{1F3FE}", "👏\u{1F3FE}", "🙏\u{1F3FE}", "🖐\u{1F3FE}", "🖕\u{1F3FE}", "🖖\u{1F3FE}", "👦\u{1F3FE}", "👧\u{1F3FE}", "👨\u{1F3FE}", "👩\u{1F3FE}", "👮\u{1F3FE}", "👰\u{1F3FE}", "👱\u{1F3FE}", "👲\u{1F3FE}", "👳\u{1F3FE}", "👴\u{1F3FE}", "👵\u{1F3FE}", "👶\u{1F3FE}", "👷\u{1F3FE}", "👸\u{1F3FE}", "💂\u{1F3FE}", "👼\u{1F3FE}", "🎅\u{1F3FE}", "🙇\u{1F3FE}", "💁\u{1F3FE}", "🙅\u{1F3FE}", "🙆\u{1F3FE}", "🙋\u{1F3FE}", "🙎\u{1F3FE}", "🙍\u{1F3FE}", "💆\u{1F3FE}", "💇\u{1F3FE}", "💅\u{1F3FE}", "👂\u{1F3FE}", "👃\u{1F3FE}", "👋\u{1F3FE}", "👍\u{1F3FE}", "👎\u{1F3FE}", "☝\u{1F3FE}", "👆\u{1F3FE}", "👇\u{1F3FE}", "👈\u{1F3FE}", "👉\u{1F3FE}", "👌\u{1F3FE}", "✌\u{1F3FE}", "👊\u{1F3FE}", "✊\u{1F3FE}", "✋\u{1F3FE}", "💪\u{1F3FE}", "👐\u{1F3FE}", "🙌\u{1F3FE}", "👏\u{1F3FE}", "🙏\u{1F3FE}", "🖐\u{1F3FE}", "🖕\u{1F3FE}", "🖖\u{1F3FE}", "🌱", "🌲", "🌳", "🌴", "🌵", "🌷", "🌸", "🌹", "🌺", "🌻", "🌼", "💐", "🌾", "🌿", "🍀", "🍁", "🍂", "🍃", "🍄", "🌰", "🐀", "🐁", "🐭", "🐹", "🐂", "🐃", "🐄", "🐮", "🐅", "🐆", "🐯", "🐇", "🐰", "🐈", "🐱", "🐎", "🐴", "🐏", "🐑", "🐐", "🐓", "🐔", "🐤", "🐣", "🐥", "🐦", "🐧", "🐘", "🐪", "🐫", "🐗", "🐖", "🐷", "🐽", "🐕", "🐩", "🐶", "🐺", "🐻", "🐨", "🐼", "🐵", "🙈", "🙉", "🙊", "🐒", "🐉", "🐲", "🐊", "🐍", "🐢", "🐸", "🐋", "🐳", "🐬", "🐙", "🐟", "🐠", "🐡", "🐚", "🐌", "🐛", "🐜", "🐝", "🐞", "🐾", "⚡️", "🔥", "🌙", "☀️", "⛅️", "☁️", "💧", "💦", "☔️", "💨", "❄️", "🌟", "⭐️", "🌠", "🌄", "🌅", "🌈", "🌊", "🌋", "🌌", "🗻", "🗾", "🌐", "🌍", "🌎", "🌏", "🌑", "🌒", "🌓", "🌔", "🌕", "🌖", "🌗", "🌘", "🌚", "🌝", "🌛", "🌜", "🌞", "🍅", "🍆", "🌽", "🍠", "🍇", "🍈", "🍉", "🍊", "🍋", "🍌", "🍍", "🍎", "🍏", "🍐", "🍑", "🍒", "🍓", "🍔", "🍕", "🍖", "🍗", "🍘", "🍙", "🍚", "🍛", "🍜", "🍝", "🍞", "🍟", "🍡", "🍢", "🍣", "🍤", "🍥", "🍦", "🍧", "🍨", "🍩", "🍪", "🍫", "🍬", "🍭", "🍮", "🍯", "🍰", "🍱", "🍲", "🍳", "🍴", "🍵", "☕️", "🍶", "🍷", "🍸", "🍹", "🍺", "🍻", "🍼🎀", "🎁", "🎂", "🎃", "🎄", "🎋", "🎍", "🎑", "🎆", "🎇", "🎉", "🎊", "🎈", "💫", "✨", "💥", "🎓", "👑", "🎎", "🎏", "🎐", "🎌", "🏮", "💍", "❤️", "💔", "💌", "💕", "💞", "💓", "💗", "💖", "💘", "💝", "💟", "💜", "💛", "💚", "💙", "🏃", "🚶", "💃", "🚣", "🏊", "🏄", "🛀", "🏂", "🎿", "⛄️", "🚴", "🚵", "🏇", "⛺️", "🎣", "⚽️", "🏀", "🏈", "⚾️", "🎾", "🏉", "⛳️", "🏆", "🎽", "🏁", "🎹", "🎸", "🎻", "🎷", "🎺", "🎵", "🎶", "🎼", "🎧", "🎤", "🎭", "🎫", "🎩", "🎪", "🎬", "🎨", "🎯", "🎱", "🎳", "🎰", "🎲", "🎮", "🎴", "🃏", "🀄️", "🎠", "🎡", "🎢", "🚃", "🚞", "🚂", "🚋", "🚝", "🚄", "🚅", "🚆", "🚇", "🚈", "🚉", "🚊", "🚌", "🚍", "🚎", "🚐", "🚑", "🚒", "🚓", "🚔", "🚨", "🚕", "🚖", "🚗", "🚘", "🚙", "🚚", "🚛", "🚜", "🚲", "🚏", "⛽️", "🚧", "🚦", "🚥", "🚀", "🚁", "✈️", "💺", "⚓️", "🚢", "🚤", "⛵️", "🚡", "🚠", "🚟", "🛂", "🛃", "🛄", "🛅", "💴", "💶", "💷", "💵", "🗽", "🗿", "🌁", "🗼", "⛲️", "🏰", "🏯", "🌇", "🌆", "🌃", "🌉", "🏠", "🏡", "🏢", "🏬", "🏭", "🏣", "🏤", "🏥", "🏦", "🏨", "🏩", "💒", "⛪️", "🏪", "🏫", "🇦🇺", "🇦🇹", "🇧🇪", "🇧🇷", "🇨🇦", "🇨🇱", "🇨🇳", "🇨🇴", "🇩🇰", "🇫🇮", "🇫🇷", "🇩🇪", "🇭🇰", "🇮🇳", "🇮🇩", "🇮🇪", "🇮🇱", "🇮🇹", "🇯🇵", "🇰🇷", "🇲🇴", "🇲🇾", "🇲🇽", "🇳🇱", "🇳🇿", "🇳🇴", "🇵🇭", "🇵🇱", "🇵🇹", "🇵🇷", "🇷🇺", "🇸🇦", "🇸🇬", "🇿🇦", "🇪🇸", "🇸🇪", "🇨🇭", "🇹🇷", "🇬🇧", "🇺🇸", "🇦🇪", "🇻🇳", "⌚️", "📱", "📲", "💻", "⏰", "⏳", "⌛️", "📷", "📹", "🎥", "📺", "📻", "📟", "📞", "☎️", "📠", "💽", "💾", "💿", "📀", "📼", "🔋", "🔌", "💡", "🔦", "📡", "💳", "💸", "💰", "💎⌚️", "📱", "📲", "💻", "⏰", "⏳", "⌛️", "📷", "📹", "🎥", "📺", "📻", "📟", "📞", "☎️", "📠", "💽", "💾", "💿", "📀", "📼", "🔋", "🔌", "💡", "🔦", "📡", "💳", "💸", "💰", "💎🚪", "🚿", "🛁", "🚽", "💈", "💉", "💊", "🔬", "🔭", "🔮", "🔧", "🔪", "🔩", "🔨", "💣", "🚬", "🔫", "🔖", "📰", "🔑", "✉️", "📩", "📨", "📧", "📥", "📤", "📦", "📯", "📮", "📪", "📫", "📬", "📭", "📄", "📃", "📑", "📈", "📉", "📊", "📅", "📆", "🔅", "🔆", "📜", "📋", "📖", "📓", "📔", "📒", "📕", "📗", "📘", "📙", "📚", "📇", "🔗", "📎", "📌", "✂️", "📐", "📍", "📏", "🚩", "📁", "📂", "✒️", "✏️", "📝", "🔏", "🔐", "🔒", "🔓", "📣", "📢", "🔈", "🔉", "🔊", "🔇", "💤", "🔔", "🔕", "💭", "💬", "🚸", "🔍", "🔎", "🚫", "⛔️", "📛", "🚷", "🚯", "🚳", "🚱", "📵", "🔞", "🉑", "🉐", "💮", "㊙️", "㊗️", "🈴", "🈵", "🈲", "🈶", "🈚️", "🈸", "🈺", "🈷", "🈹", "🈳", "🈂", "🈁", "🈯️", "💹", "❇️", "✳️", "❎", "✅", "✴️", "📳", "📴", "🆚", "🅰", "🅱", "🆎", "🆑", "🅾", "🆘", "🆔", "🅿️", "🚾", "🆒", "🆓", "🆕", "🆖", "🆗", "🆙", "🏧", "♈️", "♉️", "♊️", "♋️", "♌️", "♍️", "♎️", "♏️", "♐️", "♑️", "♒️", "♓️", "🚻", "🚹", "🚺", "🚼", "♿️", "🚰", "🚭", "🚮", "▶️", "◀️", "🔼", "🔽", "⏩", "⏪", "⏫", "⏬", "➡️", "⬅️", "⬆️", "⬇️", "↗️", "↘️", "↙️", "↖️", "↕️", "↔️", "🔄", "↪️", "↩️", "⤴️", "⤵️", "🔀", "🔁", "🔂", "#️⃣", "0️⃣", "1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣", "6️⃣", "7️⃣", "8️⃣", "9️⃣", "🔟", "🔢", "🔤", "🔡", "🔠", "ℹ️", "📶", "🎦", "🔣", "➕", "➖", "〰", "➗", "✖️", "✔️", "🔃", "™", "©", "®", "💱", "💲", "➰", "➿", "〽️", "❗️", "❓", "❕", "❔", "‼️", "⁉️", "❌", "⭕️", "💯", "🔚", "🔙", "🔛", "🔝", "🔜", "🌀", "Ⓜ️", "⛎", "🔯", "🔰", "🔱", "⚠️", "♨️", "♻️", "💢", "💠", "♠️", "♣️", "♥️", "♦️", "☑️", "⚪️", "⚫️", "🔘", "🔴", "🔵", "🔺", "🔻", "🔸", "🔹", "🔶", "🔷", "▪️", "▫️", "⬛️", "⬜️", "◼️", "◻️", "◾️", "◽️", "🔲", "🔳", "🕐", "🕑", "🕒", "🕓", "🕔", "🕕", "🕖", "🕗", "🕘", "🕙", "🕚", "🕛", "🕜", "🕝", "🕞", "🕟", "🕠", "🕡", "🕢", "🕣", "🕤", "🕥", "🕦", "🕧", "🌡", "🌢", "🌣", "🌤", "🌥", "🌦", "🌧", "🌨", "🌩", "🌪", "🌫", "🌬", "🌶", "🍽", "🎔", "🎕", "🎖", "🎗", "🎘", "🎙", "🎚", "🎛", "🎜", "🎝", "🎞", "🎟", "🏅", "🏋", "🏌", "🏍", "🏎", "🏔", "🏕", "🏖", "🏗", "🏘", "🏙", "🏚", "🏛", "🏜", "🏝", "🏞", "🏟", "🏱", "🏲", "🏳", "🏴", "🏵", "🏶", "🏷", "🐿", "👁", "📸", "📽", "📾", "🔾", "🔿", "🕄", "🕅", "🕆", "🕇", "🕈", "🕉", "🕊", "🕨", "🕩", "🕪", "🕫", "🕬", "🕭", "🕮", "🕯", "🕰", "🕱", "🕲", "🕳", "🕴", "🕵", "🕶", "🕷", "🕸", "🕹", "🕻", "🕼", "🕽", "🕾", "🕿", "🖀", "🖁", "🖂", "🖃", "🖄", "🖅", "🖆", "🖇", "🖈", "🖉", "🖊", "🖋", "🖌", "🖍", "🖎", "🖏", "🖑", "🖒", "🖓", "🖔", "🖗", "🖘", "🖙", "🖚", "🖛", "🖜", "🖝", "🖞", "🖟", "🖠", "🖡", "🖢", "🖣", "🖥", "🖦", "🖧", "🖨", "🖩", "🖪", "🖫", "🖬", "🖭", "🖮", "🖯", "🖰", "🖱", "🖲", "🖳", "🖴", "🖵", "🖶", "🖷", "🖸", "🖹", "🖺", "🖻", "🖼", "🖽", "🖾", "🖿", "🗀", "🗀", "🗂", "🗃", "🗄", "🗅", "🗆", "🗇", "🗈", "🗉", "🗊", "🗋", "🗌", "🗍", "🗎", "🗏", "🗐", "🗑", "🗒", "🗓", "🗔", "🗕", "🗖", "🗗", "🗘", "🗙", "🗚", "🗛", "🗜", "🗝", "🗞", "🗟", "🗠", "🗡", "🗢", "🗣", "🗤", "🗥", "🗦", "🗧", "🗨", "🗩", "🗪", "🗫", "🗬", "🗭", "🗯", "🗯", "🗰", "🗱", "🗲", "🗳", "🗴", "🗵", "🗶", "🗷", "🗸", "🗹", "🗺", "🛆", "🛇", "🛈", "🛉", "🛊", "🛋", "🛌", "🛍", "🛎", "🛏", "🛠", "🛡", "🛢", "🛣", "🛤", "🛥", "🛦", "🛧", "🛨", "🛩", "🛪", "🛫", "🛬", "🛰", "🛱", "🛲", "🛳", "🌡", "🌢", "🌣", "🌤", "🌥", "🌦", "🌧", "🌨", "🌩", "🌪", "🌫", "🌬", "🌶", "🍽", "🎔", "🎕", "🎖", "🎗", "🎘", "🎙", "🎚", "🎛", "🎜", "🎝", "🎞", "🎟", "🏅", "🏋", "🏌", "🏍", "🏎", "🏔", "🏕", "🏖", "🏗", "🏘", "🏙", "🏚", "🏛", "🏜", "🏝", "🏞", "🏟", "🏱", "🏲", "🏳", "🏴", "🏵", "🏶", "🏷", "🐿", "👁", "📸", "📽", "📾", "🔾", "🔿", "🕄", "🕅", "🕆", "🕇", "🕈", "🕉", "🕊", "🕨", "🕩", "🕪", "🕫", "🕬", "🕭", "🕮", "🕯", "🕰", "🕱", "🕲", "🕳", "🕴", "🕵", "🕶", "🕷", "🕸", "🕹", "🕻", "🕼", "🕽", "🕾", "🕿", "🖀", "🖁", "🖂", "🖃", "🖄", "🖅", "🖆", "🖇", "🖈", "🖉", "🖊", "🖋", "🖌", "🖍", "🖎", "🖏", "🖑", "🖒", "🖓", "🖔", "🖗", "🖘", "🖙", "🖚", "🖛", "🖜", "🖝", "🖞", "🖟", "🖠", "🖡", "🖢", "🖣", "🖥", "🖦", "🖧", "🖨", "🖩", "🖪", "🖫", "🖬", "🖭", "🖮", "🖯", "🖰", "🖱", "🖲", "🖳", "🖴", "🖵", "🖶", "🖷", "🖸", "🖹", "🖺", "🖻", "🖼", "🖽", "🖾", "🖿", "🗀", "🗀", "🗂", "🗃", "🗄", "🗅", "🗆", "🗇", "🗈", "🗉", "🗊", "🗋", "🗌", "🗍", "🗎", "🗏", "🗐", "🗑", "🗒", "🗓", "🗔", "🗕", "🗖", "🗗", "🗘", "🗙", "🗚", "🗛", "🗜", "🗝", "🗞", "🗟", "🗠", "🗡", "🗢", "🗣", "🗤", "🗥", "🗦", "🗧", "🗨", "🗩", "🗪", "🗫", "🗬", "🗭", "🗯", "🗯", "🗰", "🗱", "🗲", "🗳", "🗴", "🗵", "🗶", "🗷", "🗸", "🗹", "🗺", "🛆", "🛇", "🛈", "🛉", "🛊", "🛋", "🛌", "🛍", "🛎", "🛏", "🛠", "🛡", "🛢", "🛣", "🛤", "🛥", "🛦", "🛧", "🛨", "🛩", "🛪", "🛫", "🛬", "🛰", "🛱", "🛲", "🛳"] 
    
    if not vname
      result = false
    #genuine locations have proper text formatting 
    elsif vname.downcase == vname || vname.upcase == vname
      result = false
    #check for emojis
    elsif (vname =~ /[\u{203C}\u{2049}\u{20E3}\u{2122}\u{2139}\u{2194}-\u{2199}\u{21A9}-\u{21AA}\u{231A}-\u{231B}\u{23E9}-\u{23EC}\u{23F0}\u{23F3}\u{24C2}\u{25AA}-\u{25AB}\u{25B6}\u{25C0}\u{25FB}-\u{25FE}\u{2600}-\u{2601}\u{260E}\u{2611}\u{2614}-\u{2615}\u{261D}\u{263A}\u{2648}-\u{2653}\u{2660}\u{2663}\u{2665}-\u{2666}\u{2668}\u{267B}\u{267F}\u{2693}\u{26A0}-\u{26A1}\u{26AA}-\u{26AB}\u{26BD}-\u{26BE}\u{26C4}-\u{26C5}\u{26CE}\u{26D4}\u{26EA}\u{26F2}-\u{26F3}\u{26F5}\u{26FA}\u{26FD}\u{2702}\u{2705}\u{2708}-\u{270C}\u{270F}\u{2712}\u{2714}\u{2716}\u{2728}\u{2733}-\u{2734}\u{2744}\u{2747}\u{274C}\u{274E}\u{2753}-\u{2755}\u{2757}\u{2764}\u{2795}-\u{2797}\u{27A1}\u{27B0}\u{2934}-\u{2935}\u{2B05}-\u{2B07}\u{2B1B}-\u{2B1C}\u{2B50}\u{2B55}\u{3030}\u{303D}\u{3297}\u{3299}\u{1F004}\u{1F0CF}\u{1F170}-\u{1F171}\u{1F17E}-\u{1F17F}\u{1F18E}\u{1F191}-\u{1F19A}\u{1F1E7}-\u{1F1EC}\u{1F1EE}-\u{1F1F0}\u{1F1F3}\u{1F1F5}\u{1F1F7}-\u{1F1FA}\u{1F201}-\u{1F202}\u{1F21A}\u{1F22F}\u{1F232}-\u{1F23A}\u{1F250}-\u{1F251}\u{1F300}-\u{1F320}\u{1F330}-\u{1F335}\u{1F337}-\u{1F37C}\u{1F380}-\u{1F393}\u{1F3A0}-\u{1F3C4}\u{1F3C6}-\u{1F3CA}\u{1F3E0}-\u{1F3F0}\u{1F400}-\u{1F43E}\u{1F440}\u{1F442}-\u{1F4F7}\u{1F4F9}-\u{1F4FC}\u{1F500}-\u{1F507}\u{1F509}-\u{1F53D}\u{1F550}-\u{1F567}\u{1F5FB}-\u{1F640}\u{1F645}-\u{1F64F}\u{1F680}-\u{1F68A}]/) == 0 
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
          instagram_location_name_clean = instagram.location.name.downcase.gsub("the", "").gsub("café", "").gsub(" a ", "").gsub("cafe", "").gsub("restaurant", "").gsub("club", "").gsub("downtown", "").gsub("updtown", "").gsub("park", "").gsub("national", "").gsub(" ", "")
          venue_name_clean = self.name.downcase.gsub("the", "").gsub(" a ", "").gsub("café", "").gsub("cafe", "").gsub("restaurant", "").gsub("club", "").gsub("downtown", "").gsub("updtown", "").gsub("park", "").gsub("national", "").gsub(" ", "")
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
        for instagram in nearby_instagram_content
          if (instagram.location.id == self.instagram_location_id && VenueComment.where("instagram_id = ?", instagram.id).any? == false) && DateTime.strptime("#{instagram.created_time}",'%s') >= Time.now - 24.hours
            puts("converting instagram to #{self.name} Venue Comment from #{instagram.location.name}")
            vc = VenueComment.new(:venue_id => self.id, :image_url_1 => instagram.images.standard_resolution.url, :media_type => "image", :content_origin => "instagram", :time_wrapper => DateTime.strptime("#{instagram.created_time}",'%s'), :instagram_id => instagram.id, :thirdparty_username => instagram.user.username)
            vc.save
            instagram_tags = instagram.tags
            instagram_captions = instagram.caption.text.split rescue nil
            vc.delay.extract_instagram_meta_data(instagram_tags, instagram_captions)
            venue_comments_created += 1
            vote = LytitVote.new(:value => 1, :venue_id => self.id, :user_id => nil, :venue_rating => self.rating ? self.rating : 0, 
                  :prime => 0.0, :raw_value => 1.0, :time_wrapper => DateTime.strptime("#{instagram.created_time}",'%s'))     
            vote.save
            self.update_r_up_votes(DateTime.strptime("#{instagram.created_time}",'%s'))
            self.update_columns(latest_posted_comment_time: DateTime.strptime("#{instagram.created_time}",'%s'))
            
            if not LytSphere.where("venue_id = ?", self.id).any?
              LytSphere.create_new_sphere(self)
            end            
          end
        end

        #if little content is offered on the geo pull make a venue specific pull
        if venue_comments_created < 3
          puts ("making a venue get instagrams calls")
          self.get_instagrams(true)
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
  end

  #Instagram specific LYTiT venue search-match  
  def self.fetch_venues_for_instagram_pull(vname, lat, long, inst_loc_id)
    lookup = InstagramLocationIdLookup.find_by_instagram_location_id(inst_loc_id)
    if lookup != nil
      return lookup.venue
    else
      #Check if there is a direct name match in proximity
      name_lookup = Venue.where("LOWER(name) = ? AND ABS(#{lat} - latitude) <= 0.3 AND ABS(#{long} - longitude) <= 0.3", vname.to_s.downcase).first
      if name_lookup != nil
        return name_lookup
      else
        search_part = nil
        radius = 500
        boundries = bounding_box(radius, lat, long)
        venues = Venue.where("LOWER(name) LIKE ? AND ABS(#{lat} - latitude) <= 0.5 AND ABS(#{long} - longitude) <= 0.5", '%' + vname.to_s.downcase + '%')
        if venues.count == 0
          vname.to_s.downcase.split.each do |part| 
            if not ['the', 'a', 'cafe', 'restaurant', 'club', 'park'].include? part
              puts "search part extracted"
              search_part = part
              break
            end
          end

          if search_part != nil
            venues = Venue.where("LOWER(name) LIKE ? AND ABS(#{lat} - latitude) <= 0.5 AND ABS(#{long} - longitude) <= 0.5", '%' + search_part + '%')
          end

          if venues.count == 0
            venues = Venue.where("latitude > ? AND latitude < ? AND longitude > ? AND longitude < ?", boundries["min_lat"], boundries["max_lat"], boundries["min_long"], boundries["max_long"])
          end
        end

        if venues.count != 0
          for venue in venues
            if venue.name.downcase == vname.downcase #Is there a direct string match?
              lookup = venue
              break
            end

            if ( ((venue.name.downcase).include?(vname.downcase) && vname.length.to_f/venue.name.length.to_f > 0.5) || ((vname.downcase).include?(venue.name.downcase) && venue.name.length.to_f/vname.length.to_f > 0.5) ) #Are they substrings?
              #parks tend to cause problems because of their general naming convetions which often overlap with other establishments, so we check explicitly if we are dealing with a park
              if (venue.name.downcase.include?("park") && vname.downcase.include?("park")) || (venue.name.downcase.include?("park") == false && vname.downcase.include?("park") == false)
                lookup = venue
                break
              end
            end

            require 'fuzzystringmatch'
            jarow = FuzzyStringMatch::JaroWinkler.create( :native )

            if vname.include?(',') || venue.name.include?(',')
              no_comma_vname = vname.slice(0..(vname.index(',')-1)) rescue vname
              no_comma_venue_name = venue.name.slice(0..(venue.name.index(',')-1)) rescue venue.name
              if p jarow.getDistance(no_comma_vname, no_comma_venue_name) > 0.9
                lookup = venue
                break
              end
            end          
          
            if p jarow.getDistance(venue.name.downcase.gsub("the", "").gsub(" a ", "").gsub("cafe", "").gsub("restaurant", "").gsub("park", "").gsub("club", "").gsub(" ", ""), vname.downcase.gsub("the", "").gsub(" a ", "").gsub("cafe", "").gsub("restaurant", "").gsub("park", "").gsub("club", "").gsub(" ", "")) >= 0.8 && ((venue.name.downcase.include?("park") && vname.downcase.include?("park")) || (venue.name.downcase.include?("park") == false && vname.downcase.include?("park") == false))
              lookup = venue
              break
            end
          end
        end

        if lookup != nil 
          if lookup.time_zone == nil #Add timezone of venue if not present
            Timezone::Configure.begin do |c|
              c.username = 'LYTiT'
            end
            timezone = Timezone::Zone.new :latlon => [lat, long] rescue nil
            lookup.time_zone = timezone.active_support_time_zone rescue nil
          end

          if lookup.time_zone_offset == nil
            lookup.time_zone_offset = Time.now.in_time_zone(lookup.time_zone).utc_offset/3600.0 rescue nil
          end
        end

        #if location not found in LYTiT database create new venue
        if lookup == nil
          Timezone::Configure.begin do |c|
            c.username = 'LYTiT'
          end
          timezone = Timezone::Zone.new :latlon => [lat, long] rescue nil
          
          venue = Venue.new
          venue.name = vname
          venue.latitude = lat
          venue.longitude = long
          venue.time_zone = timezone.active_support_time_zone rescue nil
          venue.time_zone_offset = Time.now.in_time_zone(timezone.active_support_time_zone).utc_offset/3600.0 rescue nil
          venue.verified = false

          if lat < 0 && long >= 0
            quadrant = "a"
          elsif lat < 0 && long < 0
            quadrant = "b"
          elsif lat >= 0 && long < 0
            quadrant = "c"
          else
            quadrant = "d"
          end
          venue.l_sphere = quadrant+(venue.latitude.round(1).abs).to_s+(venue.longitude.round(1).abs).to_s

          venue.fetched_at = Time.now
          venue.save
          lookup = venue
          lookup.update_columns(instagram_location_id: inst_loc_id)

          inst_location_id_tracker_lookup_entry = InstagramLocationIdLookup.new(:venue_id => lookup.id, :instagram_location_id => inst_loc_id)
          inst_location_id_tracker_lookup_entry.save
        end

        return lookup
      end
    end
  end

  #Instagram API locational content pulls. The min_id_consideration variable is used because we also call get_instagrams sometimes when setting an instagram location id (see bellow) and thus 
  #need access to all recent instagrams
  def get_instagrams(day_pull)
    new_media_created = false
    last_instagram_id = nil

    instagram_access_token_obj = InstagramAuthToken.where("is_valid IS TRUE").sample(1).first
    instagram_access_token = instagram_access_token_obj.token rescue nil
    if instagram_access_token != nil
      instagram_access_token_obj.increment!(:num_used, 1) rescue nil
    end
    client = Instagram.client(:access_token => instagram_access_token)

    if day_pull == true || ((last_instagram_pull_time == nil or last_instagram_pull_time <= Time.now - 24.hours) || self.last_instagram_post == nil)
      instagrams = client.location_recent_media(self.instagram_location_id, :min_timestamp => (Time.now-24.hours).to_time.to_i) rescue self.rescue_instagram_api_call(instagram_access_token, day_pull)
    else
      instagrams = client.location_recent_media(self.instagram_location_id, :min_id => self.last_instagram_post) rescue self.rescue_instagram_api_call(instagram_access_token, day_pull)
    end

    instagrams_count = instagrams.count

    if instagrams != nil and instagrams_count > 0
      instagrams.each_with_index do |instagram, index|
        new_media_created = VenueComment.convert_instagram_to_vc(instagram, self, nil)
        if index+1 == instagrams_count
          last_instagram_id = instagram.id
        end
      end
      self.update_columns(last_instagram_post: last_instagram_id)  
    end
    self.update_columns(last_instagram_pull_time: Time.now)
    return new_media_created
  end

  def rescue_instagram_api_call(invalid_instagram_access_token, day_pull)
    if invalid_instagram_access_token != nil
      InstagramAuthToken.find_by_token(invalid_instagram_access_token).update_columns(is_valid: false)
    end

    if day_pull == true
      Instagram.location_recent_media(self.instagram_location_id, :min_timestamp => (Time.now-24.hours).to_time.to_i)
    else
      Instagram.location_recent_media(self.instagram_location_id, :min_id => self.last_instagram_post)
    end

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
      
      surrounding_lyts_radius = 10000
      if not Venue.within(Venue.meters_to_miles(surrounding_lyts_radius.to_i), :origin => [lat, long]).where("rating > 0").any?
        new_instagrams = Instagram.media_search(lat, long, :distance => 5000, :count => 100)

        for instagram in new_instagrams
          VenueComment.convert_instagram_to_vc(instagram, nil, nil)
        end
      end
    end

  end
  #----------------------------------------------------------------------------->


  #IV. Additional/Misc Functionalities ------------------------------------------->
  #determines the type of venue, ie, country, state, city, neighborhood, or just a regular establishment.
  def last_post_time
    (Time.now - latest_posted_comment_time)
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
    meter_radius = 400
    surroundings = Venue.within(Venue.meters_to_miles(meter_radius.to_i), :origin => [lat, long]).where("has_been_voted_at = TRUE AND is_address = FALSE").order('distance ASC limit 10')
  end

  def cord_to_city
    query = self.latitude.to_s + "," + self.longitude.to_s
    result = Geocoder.search(query).first 
    result_city = result.city || result.county
    result_city.slice!(" County")
    self.update_columns(city: result_city)
    return result_city
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
    Venue.update_all(rating: 0.0)
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
  def pull_twitter_tweets
    if self.last_twitter_pull_time == nil or (Time.now - self.last_twitter_pull_time > 0.minutes)
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = '286I5Eu8LD64ApZyIZyftpXW2'
        config.consumer_secret     = '4bdQzIWp18JuHGcKJkTKSl4Oq440ETA636ox7f5oT0eqnSKxBv'
        config.access_token        = '2846465294-QPuUihpQp5FjOPlKAYanUBgRXhe3EWAUJMqLw0q'
        config.access_token_secret = 'mjYo0LoUnbKT4XYhyNfgH4n0xlr2GCoxBZzYyTPfuPGwk'
      end

      radius = 0.1 #miles

      last_tweet_id = Tweet.where("venue_id = ?", self.id).order("twitter_id desc").first.try(:twitter_id)
      if last_tweet_id != nil
        venue_tweets = client.search("#{self.name} -rt", result_type: "recent", geo_code: "#{latitude},#{longitude},#{radius}mi", since_id: "#{last_tweet_id}").take(20).collect
      else
        venue_tweets = client.search("#{self.name} -rt", result_type: "recent", geo_code: "#{latitude},#{longitude},#{radius}mi").take(20).collect
      end

      for venue_tweet in venue_tweets
       Tweet.create!(:twitter_id => venue_tweet.id, :tweet_text => venue_tweet.text, :author_id => venue_tweet.user.id, :handle => venue_tweet.screen_name, :author_name => venue_tweet.user.name, :author_avatar => venue_tweet.user.profile_image_url.to_s, :timestamp => venue_tweet.created_at, :from_cluster => false, :venue_id => self.id, :popularity_score => Tweet.popularity_score_calculation(venue_tweet.user.followers_count, venue_tweet.retweet_count, venue_tweet.favorite_count)) rescue "Oops, Tweet already pulled!"
      end

      self.update_columns(last_twitter_pull_time: Time.now)
    end
  end

  def self.cluster_twitter_tweets(cluster_lat, cluster_long, zoom_level, map_scale, cluster, venue_ids)
    cluster_venue_ids = venue_ids.split(',').map(&:to_i)
    if cluster.last_twitter_pull_time == nil or cluster.last_twitter_pull_time > Time.now - 0.minutes
      cluster.update_columns(last_twitter_pull_time: Time.now)
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = '286I5Eu8LD64ApZyIZyftpXW2'
        config.consumer_secret     = '4bdQzIWp18JuHGcKJkTKSl4Oq440ETA636ox7f5oT0eqnSKxBv'
        config.access_token        = '2846465294-QPuUihpQp5FjOPlKAYanUBgRXhe3EWAUJMqLw0q'
        config.access_token_secret = 'mjYo0LoUnbKT4XYhyNfgH4n0xlr2GCoxBZzYyTPfuPGwk'
      end

      radius = Venue.meters_to_miles(map_scale.to_f/2.0)
      query = ""

      underlying_venues = Venue.where("id IN (?)", cluster_venue_ids).order("popularity_rank DESC LIMIT 4").select("name")
      underlying_venues.each{|v| query+=v.name}
      tags = MetaData.cluster_top_meta_tags(venue_ids)
      tags.each{|tag| query+=tag.first.last if tag.first.last != nil || tag.first.last != ""}

      cluster_tweets = client.search(query+" -rt", result_type: "recent", geo_code: "#{cluster_lat},#{cluster_long},#{radius}mi").take(100).collect
      
      for cluster_tweet in cluster_tweets
        Tweet.create!(:twitter_id => cluster_tweet.id, :tweet_text => cluster_tweet.text, :author_id => cluster_tweet.user.id, :handle => cluster_tweet.screen_name, :author_name => cluster_tweet.user.name, :author_avatar => cluster_tweet.user.profile_image_url.to_s, :timestamp => cluster_tweet.created_at, :from_cluster => true, :latitude => cluster_lat, :longitude => cluster_long, :popularity_score => Tweet.popularity_score_calculation(cluster_tweet.user.followers_count, cluster_tweet.retweet_count, cluster_tweet.favorite_count))
      end

    end
  end

  def self.raw_cluster_twitter_tweets(cluster_lat, cluster_long, zoom_level, map_scale, cluster, venue_ids)
    cluster_venue_ids = venue_ids.split(',').map(&:to_i)
    if cluster.last_twitter_pull_time == nil or cluster.last_twitter_pull_time > Time.now - 0.minutes
      cluster.update_columns(last_twitter_pull_time: Time.now)
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = '286I5Eu8LD64ApZyIZyftpXW2'
        config.consumer_secret     = '4bdQzIWp18JuHGcKJkTKSl4Oq440ETA636ox7f5oT0eqnSKxBv'
        config.access_token        = '2846465294-QPuUihpQp5FjOPlKAYanUBgRXhe3EWAUJMqLw0q'
        config.access_token_secret = 'mjYo0LoUnbKT4XYhyNfgH4n0xlr2GCoxBZzYyTPfuPGwk'
      end

      radius = Venue.meters_to_miles(200)
      tag_query = ""
      location_query = ""
      underlying_venues = Venue.where("id IN (?)", cluster_venue_ids).order("popularity_rank DESC LIMIT 4").select("name")
      underlying_venues.each{|v| location_query+=(v.name+" OR ")}
      tags = MetaData.cluster_top_meta_tags(venue_ids)
      tags.each{|tag| tag_query+=(tag.first.last+" OR ") if tag.first.last != nil || tag.first.last != ""}
      
      location_query.chomp!(" OR ") 
      tag_query.chomp!(" OR ") 

      location_cluster_tweets = client.search(location_query+" -rt", result_type: "recent", geo_code: "#{cluster_lat},#{cluster_long},#{radius}mi").take(20).collect.to_a
      tag_query_tweets = client.search(tag_query+" -rt", result_type: "recent", geo_code: "#{cluster_lat},#{cluster_long},#{radius}mi").take(20).collect.to_a
      total_tweets = []
      total_tweets << location_cluster_tweets
      total_tweets << tag_query_tweets
      flat_total_tweets = total_tweets.flatten
      return flat_total_tweets
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
    #if not self.rating || self.rating.round(1) == 0.0
    #  visible = false
    #end

    if (Time.now - latest_posted_comment_time)/60.0 >= LytitConstants.threshold_to_venue_be_shown_on_map
      visible = false
    end

    if visible == false
      self.update_columns(rating: 0.0)
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

end
