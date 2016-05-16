class Venue < ActiveRecord::Base
  include PgSearch
  Geokit::default_units = :kms

  acts_as_mappable :default_units => :kms,
                     :default_formula => :sphere,
                     :distance_field_name => :distance,
                     :lat_column_name => :latitude,
                     :lng_column_name => :longitude

  validates :name, presence: true
  validates :latitude, presence: true
  validates :longitude, presence: true

  has_many :venue_ratings, :dependent => :destroy
  has_many :venue_comments, :dependent => :destroy
  has_many :tweets, :dependent => :destroy
  has_many :lyt_spheres, :dependent => :destroy
  has_many :lytit_votes, :dependent => :destroy
  has_many :meta_datas, :dependent => :destroy
  has_many :instagram_location_id_lookups, :dependent => :destroy
  has_many :feed_venues
  has_many :feeds, through: :feed_venues
  has_many :activities, :dependent => :destroy
  has_many :events, :dependent => :destroy

  has_many :favorite_venues, :dependent => :destroy
  has_many :moment_requests, :dependent => :destroy


  pg_search_scope :name_search, #name and/or associated meta data
    :against => [:ts_name_vector, :metaphone_name_vector],
    :using => {
      :tsearch => {
        :normalization => 2,
        :dictionary => 'simple',
        :any_word => true,
        :prefix => true,
        :tsvector_column => 'ts_name_vector',
      },
      :dmetaphone => {
        :tsvector_column => "metaphone_name_vector",
        #:prefix => true,
      },  
    },
    :ranked_by => "0.5*:trigram + :tsearch +:dmetaphone" #+ 0.3*Cast(venues.verified as integer)"#{}"(((:dmetaphone) + 1.5*(:trigram))*(:tsearch) + (:trigram))"    

  pg_search_scope :name_city_search, #name and/or associated meta data
    :against => :ts_name_city_vector,
    :using => {
      :tsearch => {
        :normalization => 2,
        :dictionary => 'simple',
        :any_word => true,
        :prefix => true,
        :tsvector_column => 'ts_name_city_vector',
      }  
    },
    :ranked_by => "0.5*:trigram + :tsearch +:dmetaphone"

  pg_search_scope :name_country_search, #name and/or associated meta data
    :against => :ts_name_country_vector,
    :using => {
      :tsearch => {
        :normalization => 2,
        :dictionary => 'simple',
        :any_word => true,
        :prefix => true,
        :tsvector_column => 'ts_name_country_vector',
      }  
    },
    :ranked_by => "0.5*:trigram + :tsearch +:dmetaphone"


  pg_search_scope :name_search_expd, #name and/or associated meta data
    :against => [:ts_name_vector_expd, :metaphone_name_vector_expd],
    :using => {
      :tsearch => {
        :normalization => 1,
        :dictionary => 'simple',
        :any_word => true,
        :prefix => true,
        :tsvector_column => 'ts_name_vector_expd',
      },
      :dmetaphone => {
        :tsvector_column => "metaphone_name_vector_expd",
        #:prefix => true,
      }  
    },
    :ranked_by => ":dmetaphone + :trigram*5 +:tsearch*4" 


  pg_search_scope :phonetic_search,
              :against => "metaphone_name_vector",
              :using => {
                :dmetaphone => {
                  :tsvector_column => "metaphone_name_vector",
                  :prefix => true
                }  
              },
              :ranked_by => ":dmetaphone"# + (0.25 * :trigram)"#":trigram"#              


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

  pg_search_scope :meta_search, #name and/or associated meta data
    against: :meta_data_vector,
    using: {
      tsearch: {
        dictionary: 'english',
        #any_word: true,
        #prefix: true,
        tsvector_column: 'meta_data_vector'
      }
    }

  pg_search_scope :interest_search, #name and/or associated meta data
    against: :descriptives_vector,
    using: {
      tsearch: {
        dictionary: 'english',
        any_word: true,
        prefix: true,
        tsvector_column: 'descriptives_vector'
      }
    }  
                

  scope :close_to, -> (latitude, longitude, distance_in_meters = 2000) {
    where(%{
      ST_DWithin( venues.lonlat_geography, ST_GeographyFromText('SRID=4326;POINT(%f %f)'), %d )
    } % [longitude, latitude, distance_in_meters])
  }

  scope :far_from, -> (latitude, longitude, distance_in_meters = 2000) {
    where(%{
      NOT ST_DWithin( venues.lonlat_geography, ST_GeographyFromText('SRID=4326;POINT(%f %f)'), %d )
    } % [longitude, latitude, distance_in_meters])
  }

  scope :inside_box, -> (sw_longitude, sw_latitude, ne_longitude, ne_latitude) {
    where(%{
        venues.lonlat_geometry @ ST_MakeEnvelope(%f, %f, %f, %f, 4326) 
        } % [sw_longitude, sw_latitude, ne_longitude, ne_latitude])
  }

  scope :visible, -> { joins(:lytit_votes).where('lytit_votes.created_at > ?', Time.now - LytitConstants.threshold_to_venue_be_shown_on_map.minutes) }



  #TABLE OF CONTENTS
  #I.Creation Methods
  #II.Search Method
  #III.Ranking Methods
  #IV.Selection 
  #V.Content Methods
  #VI.Attribute Methods
  #VII.Validation Methods
  #VIII.Calibration Methods
  #IV.Helper Methods
  #V.Cleanups
  #------APIs------
  #I.Instagram
  #II.Twitter
  #III.Foursquare


#===============================================================================================
# CREATION =====================================================================================
#===============================================================================================

  def self.create_new_db_entry(name, address, city, state, country, postal_code, phone, latitude, longitude, instagram_location_id, origin_vortex, is_proposed=false)
    venue = Venue.create!(:name => name, :latitude => latitude, :longitude => longitude, :fetched_at => Time.now)
    
    if city == nil
      #closest_venue = Venue.within(10, :units => :kms, :origin => [latitude, longitude]).where("city is not NULL").order("distance ASC").first
      closest_venue = Venue.nearest_neighbors(latitude, longitude, 1).first
      if closest_venue != nil && closest_venue.distance_to([latitude, longitude]) <= 10
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
    if city != nil
      venue.update_columns(city: city) 
    else
      venue.update_columns(city: '') 
    end
    venue.update_columns(state: state) 
    venue.update_columns(country: country)

    if postal_code != nil
      venue.postal_code = postal_code.to_s
    end
    
    if phone != nil
      venue.phone_number = Venue.formatTelephone(phone)
    end

    venue.is_proposed = is_proposed
    venue.save

=begin
    if address != nil && name != nil
      if address.gsub(" ","").gsub(",", "") == name.gsub(" ","").gsub(",", "")
        venue.is_address = true
      end
    end
=end    

    if instagram_location_id != nil
      venue.update_columns(instagram_location_id: instagram_location_id)  
    end

    venue.save

    if origin_vortex != nil
      venue.update_columns(instagram_vortex_id: origin_vortex.id)     
    end    
    venue.delay.set_time_zone_and_offset(origin_vortex)

    if address != nil
      venue.update_columns(verified: true)
    end
    
    venue.update_columns(lonlat_geometry: "POINT(#{venue.longitude} #{venue.latitude})")
    venue.update_columns(lonlat_geography: "POINT(#{venue.longitude} #{venue.latitude})")

    return venue    
  end



#===============================================================================================
# SEARCH =======================================================================================
#===============================================================================================
  def Venue.fill_spatial_columns
    for venue in Venue.all 
      venue.update_columns(lonlat_geometry: "POINT(#{venue.longitude} #{venue.latitude})")
      venue.update_columns(lonlat_geography: "POINT(#{venue.longitude} #{venue.latitude})")
    end
  end

  def Venue.nearest_neighbors(lat, long, bound_radius=nil, count=10)
    if bound_radius
      bounds = Geokit::Bounds.from_point_and_radius([lat, long], bound_radius)
      Venue.all.order("lonlat_geometry <-> st_point(#{long},#{lat})").in_bounds(bounds).limit(count)
    else
      Venue.all.order("lonlat_geometry <-> st_point(#{long},#{lat})").limit(count)
    end
  end

  def nearest_neighbors_raw_with_distance(count=10)
    sql = "SELECT id, name, lonlat_geometry <-> st_point(#{self.longitude},#{self.latitude}) AS distance FROM venues ORDER BY distance LIMIT #{count}"
    ActiveRecord::Base.connection.execute(sql)
  end

  #Fetch Lytit Venues related to query (both textual and meta). Used for searching.
  def self.fetch(query, position_lat, position_long, view_box, is_meta_search=false)
    if query != nil && query != ""
      central_screen_point = [(view_box[:ne_lat]-view_box[:sw_lat])/2.0 + view_box[:sw_lat], (view_box[:ne_long]-view_box[:sw_long])/2.0 + view_box[:sw_long]]

      if is_meta_search == true        
        if Geocoder::Calculations.distance_between(central_screen_point, [position_lat, position_long], :units => :km) <= 20 and Geocoder::Calculations.distance_between(central_screen_point, [view_box[:ne_lat], view_box[:ne_long]], :units => :km) <= 100 
          #searching around user since screen is near users location.
          search_box = Geokit::Bounds.from_point_and_radius(central_screen_point, 10, :units => :kms)
          surrounding_meta_results = Venue.in_bounds(search_box).where("color_rating > -1.0").interest_search(query).limit(20)
        else
          #searching in view
          in_view_results = Venue.where("latitude > ? AND latitude < ? AND longitude > ? AND longitude < ?", view_box[:sw_lat], view_box[:ne_lat], view_box[:sw_long], view_box[:ne_long]).where("rating IS NOT NULL").interest_search(query).limit(20)
        end

      else
        #Lytit DB search that takes into consideration user coordinates and screen view.
        if (view_box[:ne_lat] != 0.0 && view_box[:ne_long] != 0.0) and (view_box[:sw_lat] != 0.0 && view_box[:sw_long] != 0.0)
          if Geocoder::Calculations.distance_between(central_screen_point, [position_lat, position_long], :units => :km) <= 20 and Geocoder::Calculations.distance_between(central_screen_point, [view_box[:ne_lat], view_box[:ne_long]], :units => :km) <= 100
              #Surrounding search
              search_box = Geokit::Bounds.from_point_and_radius(central_screen_point, 20, :units => :kms)
              surrounding_search = Venue.search(query, true, search_box, nil)
          else
              #In view search
              inview_search = Venue.search(query, true, nil, view_box)
          end
        else
          Venue.search(query, true, nil, nil)
        end
      end
    else
      []
    end
  end

  #Fetch a single venue or create it if not present in DB. Used for assigning Venues to things.
  def self.fetch_or_create(vname, vaddress, vcity, vstate, vcountry, vpostal_code, vphone, vlatitude, vlongitude, is_proposed_location=false)
    downcase_name = v.name.downcase
    lat_long_lookup = Venue.where("latitude = ? AND longitude = ?", vlatitude, vlongitude).fuzzy_name_search(vname, 0.8).first

    if lat_long_lookup == nil 
      
      center_point = [vlatitude, vlongitude]
      if downcase_name.include? "park" or downcase_name.include? "university"
        search_radius = 10 #kms 
      elsif downcase_name.include? "center" or downcase_name.include? "stadium" or downcase_name.include? "square"
        search_radius = 0.5
      else
        search_radius = 0.1
      end
      search_box = Geokit::Bounds.from_point_and_radius(center_point, search_radius, :units => :kms)
      
      if is_proposed_location == true
        vname = vname.titleize
      end
      if is_proposed_location
        min_pg_search_rank = 0.3
      else
        min_pg_search_rank = 0.2
      end
      result = Venue.in_bounds(search_box).name_search(vname).where("pg_search.rank >= ?", min_pg_search_rank).order("lonlat_geometry <-> st_point(#{vlongitude},#{vlatitude})").first

=begin    
      if lat_long_lookup == nil
        center_point = [vlatitude, vlongitude]
        search_box = Geokit::Bounds.from_point_and_radius(center_point, 0.250, :units => :kms)
        result = Venue.in_bounds(search_box).name_search(vname).with_pg_search_rank.where("pg_search.rank > 0.3").first
        if result == nil
          #handeling geographies
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
            #search_box = Geokit::Bounds.from_point_and_radius(center_point, 0.250, :units => :kms)
            #result = Venue.search(vname, search_box, nil).first
            result = nil
            #result = Venue.in_bounds(search_box).fuzzy_name_search(vname, 0.8).first
          end
        end
=end        
    else
      result = lat_long_lookup
    end



    if result == nil
      if vlatitude != nil && vlongitude != nil 
        result = Venue.create_new_db_entry(vname, vaddress, vcity, vstate, vcountry, vpostal_code, vphone, vlatitude, vlongitude, nil, nil, is_proposed_location)
        result.update_columns(verified: true)
      else
        return nil
      end
    end

    if vaddress != nil && result.address == nil
      result.delay.calibrate_attributes(vname, vaddress, vcity, vstate, vcountry, vpostal_code, vphone, vlatitude, vlongitude)
    end

    return result 
  end

  def Venue.query_is_meta?(query)
    VENUE_META_CATEGORIES.include? query.downcase.tr(" ", "_").singularize
  end

  def self.fetch_venues_for_instagram_pull(vname, lat, long, inst_loc_id, vortex, city=nil)
    #Reference LYTiT Instagram Location Id Database
    inst_id_lookup = InstagramLocationIdLookup.find_by_instagram_location_id(inst_loc_id)
    downcase_name = vname.downcase

    city = city || vortex.city
    if city != nil
      vname = scrub_venue_name(vname, city)
    end

    if vname != nil && vname != "" && (long != nil && lat != nil)
      if inst_id_lookup.try(:venue) != nil && inst_loc_id.to_i != 0
        result = inst_id_lookup.venue
      else
        #Check if there is a direct name match in proximity
        center_point = [lat, long]
        if downcase_name.include? "park" or downcase_name.include? "university"
          search_radius = 10 #kms 
        elsif downcase_name.include? "center" or downcase_name.include? "stadium" or downcase_name.include? "square"
          search_radius = 0.5
        else
          search_radius = 0.1
        end

        search_box = Geokit::Bounds.from_point_and_radius(center_point, search_radius, :units => :kms)

        #name_lookup = Venue.in_bounds(search_box).fuzzy_name_search(vname, 0.8).first

        name_lookup = Venue.in_bounds(search_box).name_search(vname).where("pg_search.rank >= ?", 0.1).order("lonlat_geometry <-> st_point(#{long},#{lat})").first


        #if name_lookup == nil
        #  name_lookup = Venue.in_bounds(search_box).name_search(vname).with_pg_search_rank.where("pg_search.rank > 0.3").first
        #end

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

  def Venue.fetch_for_event(vname, lat, long, vaddress, vcity, vstate, vpostal_code, vcountry)
    center_point = [lat, long]
    search_box = Geokit::Bounds.from_point_and_radius(center_point, 0.3, :units => :kms)
    name_lookup = Venue.in_bounds(search_box).fuzzy_name_search(vname, 0.85).first
    
    if name_lookup == nil
      venue = Venue.create!(:name => vname, :address => vaddress, :city => vcity, :state => vstate, :country => vcountry, :latitude => lat, :longitude => long, :verified => true)
    else
      venue = name_lookup
    end
  end

  #Main Venue database searching method
  def Venue.search(query, top_5 = false, proximity_box = nil, view_box = nil, origin_point = nil)
    if proximity_box != nil      
      search_box = proximity_box
    elsif view_box != nil 
      sw_point = Geokit::LatLng.new(view_box[:sw_lat], view_box[:sw_long])
      ne_point =Geokit::LatLng.new(view_box[:ne_lat], view_box[:ne_lat])
      search_box = Geokit::Bounds.new(sw_point, ne_point)
    else
      search_box = Geokit::Bounds.from_point_and_radius([40.741140, -73.981917], 20, :units => :kms)
    end

    query_parts = query.split    
    #First search in proximity
    nearby_results = Venue.in_bounds(search_box).name_search(query).where("pg_search.rank >= ?", 0.0).with_pg_search_rank.limit(5).to_a
    if nearby_results.first == nil or nearby_results.first.pg_search_rank < 0.4
        direct_name_results = Venue.name_search(query).where("pg_search.rank >= ?", 0.0).with_pg_search_rank.limit(5).to_a
        if direct_name_results.first == nil or direct_name_results.first.pg_search_rank < 0.3
          geography = '%'+query_parts.last.downcase+'%'
          #Nothing nearby, see if the user has specified a city at the end
          city_spec_results = Venue.name_city_search(query).where("pg_search.rank >= ? AND LOWER(city) LIKE ?", 0.0,
            geography).with_pg_search_rank.limit(5).to_a
          if city_spec_results.first == nil or city_spec_results.first.pg_search_rank < 0.4
            #Nothing super relevant came back from city, check by country
            country_spec_results = Venue.name_country_search(query).where("pg_search.rank >= ? AND LOWER(country) LIKE ?", 0.0,
              geography).with_pg_search_rank.limit(5).to_a
            if country_spec_results.first == nil or country_spec_results.first.pg_search_rank < 0.4
              p "Returning All Results"
              total_results = (nearby_results.concat(city_spec_results).concat(country_spec_results)).sort_by{|result| -result.pg_search_rank}.uniq
              #p total_results.each{|result| p"#{result.name} (#{result.pg_search_rank})"}
              if top_5 == true
                return total_results
              else
                return total_results.first
              end
            else
              p "Returning Country Results"
              #p country_spec_results.each{|result| p"#{result.name} (#{result.pg_search_rank})"}
              if top_5 == true
                return country_spec_results
              else
                return country_spec_results.first
              end
            end
          else
            p "Returning City Results"
            #p city_spec_results.each{|result| p"#{result.name} (#{result.pg_search_rank})"}
            if top_5 == true
              return city_spec_results
            else
              return city_spec_results.first
            end
          end
        else
          p "Returning Direct Name Results"
          if top_5 == true
            return direct_name_results
          else
            return direct_name_results.first
          end
        end
    else
      p "Returning Nearby Results"
      #p nearby_results.each{|result| p"#{result.name} (#{result.pg_search_rank})"}
      if top_5 == true
        return nearby_results
      else
        return nearby_results.first
      end
    end
  end

#===============================================================================================
# Content ======================================================================================
#===============================================================================================
  def add_new_post(user, post)
    vc = VenueComment.create!(:entry_type => "lytit_post", :lytit_post => post, :venue_id => self.id, :venue_details => self.partial, :user_id => user.id, :user_details => user.partial, :adjusted_sort_position => (Time.now+15.minutes).to_i)
    self.update_columns(latest_posted_comment_time: Time.now)
    self.delay(:priority => -4).calibrate_after_lytit_post(vc)    
    return vc
  end

  def calibrate_after_lytit_post(vc)
    PostPass.initiate(vc)
    if self.latest_posted_comment_time == nil or self.latest_posted_comment_time < vc.created_at
      self.update_columns(latest_posted_comment_time: vc.created_at)
    end
    
    if vc.lytit_post["comment"] != nil
      self.update_descriptives(vc.lytit_post["comment"])
    end
    latest_comment_type_times = self.latest_comment_type_times
    latest_comment_type_times["lytit_post"] = Time.now
    self.update_columns(latest_comment_type_times: latest_comment_type_times)

    self.feeds.update_all("num_moments = num_moments+1")
    self.update_rating(true, true)
    self.update_columns(latest_rating_update_time: Time.now)
    self.update_featured_comment(vc)

    self.update_rating(true, true)

    #Append comment to venues cached feed if present by adding a negative page number.
    self.rebuild_cached_vc_feed
  end

  def rebuild_cached_vc_feed
    if Rails.cache.exist?("venue/#{self.id}/comments/page_1")
      #purge all cache and rebuild feed
      page = 1
      response = true
      while response == true do
        response = (self.content_feed_page(page, true) != nil and self.content_feed_page(page, true).first != nil)
        page += 1
      end
    end    
  end  

  def content_feed_page(page_number, warming_up=false)
    api_ping_timeout = 10.minutes
    page_count = 10
    current_position = Time.now.to_i

    vc_cache_key = "venue/#{self.id}/comments/page_#{page_number}"
    
    #used to purge old pages to construct new ones after a post
    if warming_up == true
      Rails.cache.delete(vc_cache_key)
    end

    comments = Rails.cache.fetch(vc_cache_key, :expires_in => 10.minutes) do
      #Clear offset value if rebuilding feed.
      if page_number == 1
        max_vc_id = self.venue_comments.order("id DESC").first.try(:id) || -1
        self.update_columns(venue_comment_id: max_vc_id)
        
        if self.page_offset > 0
          i = 2
          #delete first 10 cached pages if present (unlikely to be more)
          for i in [2..20] 
            Rails.cache.delete("venue/#{self.id}/comments/page_#{i}")
          end
          self.update_columns(page_offset: 0)
        end
      end

      super_content_count = self.venue_comments.where("adjusted_sort_position >= ? AND adjusted_sort_position <= ?", current_position, current_position+24.hours).count

      if super_content_count > 0 && (page_offset == 0 || page_number*page_count <= page_offset)
        new_super_content_num_pages = super_content_count/page_count + (super_content_count%page_count != 0 ? 1:0)
        if new_super_content_num_pages > 1
          for i in 2..(new_super_content_num_pages)
            vc_cache_key = "venue/#{self.id}/comments/page_#{i}"
            p "Writing new Super Content to cache."
            Rails.cache.write(vc_cache_key, self.venue_comments.where("adjusted_sort_position >= ?", current_position).limit(page_count).offset((page_number-1)*page_count).to_a)
          end
        end
        self.increment!(:page_offset, new_super_content_num_pages)
        self.venue_comments.where("adjusted_sort_position >= ?", current_position).order("adjusted_sort_position DESC").limit(page_count).to_a
      else
        if (self.last_instagram_pull_time == nil or self.last_twitter_pull_time == nil) or ((Time.now - api_ping_timeout) > self.last_instagram_pull_time or (Time.now - api_ping_timeout) > self.last_twitter_pull_time)
          new_social_media = self.live_social_media_search
          p "Pinged social networks-new content count: #{new_social_media.count}"
          new_social_media_num_pages = new_social_media.count/page_count + (new_social_media.count%page_count != 0 ? 1:0)
          if new_social_media_num_pages > 0
            if new_social_media_num_pages > 1
              for i in 2..(new_social_media_num_pages)
                vc_cache_key = "venue/#{self.id}/comments/page_#{i+self.page_offset}"
                p "Writing new Social Media content to cache."
                Rails.cache.write(vc_cache_key, new_social_media.page(i, page_count), :expires_in => 10.minutes)
              end
            end
            self.increment!(:page_offset, new_social_media_num_pages)
            new_social_media.page(1, page_count) #array pagination method
          else
            #No new social media content so we move to venue comments.
            p "No new social media, returning Venue Comments"
            vcs = self.venue_comments.where("((adjusted_sort_position > ? AND entry_type != ?) OR (adjusted_sort_position > ? AND entry_type = ?)) 
              AND adjusted_sort_position < ? AND id <= ?", (Time.now-5.hours).to_i, "lytit_post", (Time.now-24.hours).to_i, "lytit_post", current_position, 
              self.venue_comment_id).limit(page_count).offset(((page_number-self.page_offset)-1)*page_count).order("adjusted_sort_position DESC")
            if vcs.count > 0
              vcs.to_a
            else
              nil
            end
          end
        else
          #The page offset value is the amount of proceeding pages filled with either super content or live social media.
          p "Straight to Venue Comments"
          vcs = self.venue_comments.where("((adjusted_sort_position > ? AND entry_type != ?) OR (adjusted_sort_position > ? AND entry_type = ?)) 
            AND adjusted_sort_position < ? AND id <= ?", (Time.now-5.hours).to_i, "lytit_post", (Time.now-24.hours).to_i, "lytit_post", current_position, 
            self.venue_comment_id).limit(page_count).offset(((page_number-self.page_offset)-1)*page_count).order("adjusted_sort_position DESC")
          if vcs.count > 0
            vcs.to_a
          else
            nil
          end
        end
      end
    end
  end

  def live_social_media_search
    require 'timeout'
    ping_timeouts = 10.minutes
    new_tweets = []
    new_instagrams = []

    if self.last_instagram_pull_time == nil or self.last_instagram_pull_time < (Time.now - ping_timeouts)
      begin
        Timeout::timeout(5) do
          new_instagrams = self.instagram_ping(false, false) || []
        end
      rescue Timeout::Error => e
        p "Instagram too slow."
      end
    end

    if self.last_twitter_pull_time == nil or self.last_twitter_pull_time < (Time.now - ping_timeouts)
      begin
        Timeout::timeout(5) do
          new_tweets = self.twitter_ping || []
        end
      rescue Timeout::Error => e
        p "Twitter too slow."
      end
    end
    
    latest_comment_type_times = self.latest_comment_type_times
    if new_instagrams.count > 0 or new_tweets.count > 0
      if new_instagrams.count > 0
        self.update_columns(last_instagram_post: new_instagrams.first["id"])
        latest_comment_type_times["instagram"] = DateTime.strptime(new_instagrams.first["created_time"],'%s')
      end

      if new_tweets.count > 0
        latest_comment_type_times["tweet"] = new_tweets.first.created_at.to_datetime
      end

      self.update_columns(latest_comment_type_times: latest_comment_type_times)
    end

    VenueComment.delay.convert_new_social_media_to_vcs(new_instagrams, new_tweets, self)
    latest_posted_comment_time = self.latest_posted_comment_time || Time.now - 5.hours
    new_tweets = (new_tweets.select{|tweet| tweet.created_at >= latest_posted_comment_time}).map(&:to_hash)
    return ((new_instagrams+new_tweets).sort_by{|content| VenueComment.thirdparty_created_at(content)}).reverse!
  end

#===============================================================================================
# Rarnking =====================================================================================
#===============================================================================================

  #A. Lytit/Color Ratings------------------------------------------------------------
  #----------------------------------------------------------------------------------
  def Venue.update_all_active_venue_ratings
    Venue.update_visibilities
    for venue in Venue.where("(rating IS NOT NULL AND latest_rating_update_time IS NOT NULL) AND latest_rating_update_time < ?", Time.now-5.minutes)
      #if venue.is_visible? == true
      #  if venue.latest_rating_update_time != nil and venue.latest_rating_update_time < Time.now - 5.minutes
      #    venue.update_rating()
      #  end
      #end
      venue.udpate_rating()
    end
  end

  def Venue.update_visibilities
    start_time = Time.now
    invisible_venues = Venue.where("rating = 0.0 OR (rating IS NOT NULL AND latest_posted_comment_time < ? AND latest_posted_comment_time > ?)", Time.now-LytitConstants.threshold_to_venue_be_shown_on_map.minutes, Time.now-24.hours)
    invisible_venues.update_all({:r_up_votes => true, :r_down_votes => true, :color_rating => -1.0, :popularity_rank => 0.0, :rating => nil})
    end_time = Time.now
    puts "Done. Time Taken: #{end_time - start_time}s"
  end

  def is_visible?
    visible = true
    latest_posted_comment_time = self.latest_posted_comment_time || Time.now
    if (self.rating == nil or self.rating.round(2) == 0.0) || (Time.now - latest_posted_comment_time)/60.0 >= (LytitConstants.threshold_to_venue_be_shown_on_map)
      visible = false
    end

    if visible == false
      self.update_columns(rating: nil)
      self.update_columns(r_up_votes: 1.0)
      self.update_columns(r_down_votes: 1.0)
      self.update_columns(color_rating: -1.0)
      self.update_columns(popularity_rank: 0.0)
    end

    return visible
  end

  def update_rating(after_post=false, lytit_post=false)
    latest_posted_comment_time = self.latest_posted_comment_time || Time.now
    old_r_up_vote_count = self.r_up_votes 
    if after_post == true
      if lytit_post == true
        new_r_up_vote_count = ((old_r_up_vote_count) * 2**((-(Time.now.utc - latest_posted_comment_time)/60.0) / (LytitConstants.vote_half_life_h))).round(4)+6.0
      else
        new_r_up_vote_count = ((old_r_up_vote_count) * 2**((-(Time.now.utc - latest_posted_comment_time)/60.0) / (LytitConstants.vote_half_life_h))).round(4)+1.0
      end
    else
      new_r_up_vote_count = ((old_r_up_vote_count) * 2**((-(Time.now.utc - latest_posted_comment_time)/60.0) / (LytitConstants.vote_half_life_h))).round(4)
    end
    self.update_columns(r_up_votes: new_r_up_vote_count)

    y = (1.0 / (1 + LytitConstants.rating_loss_l)).round(4)

    a = new_r_up_vote_count >= 1.0 ? new_r_up_vote_count : 1.0
    b = 1.0

    puts "A = #{a}, B = #{b}, Y = #{y}"


    # x = LytitBar::inv_inc_beta(a, b, y)
    # for some reason the python interpreter installed is not recognized by RubyPython
    x = `python2 -c "import scipy.special;print scipy.special.betaincinv(#{a}, #{b}, #{y})"`

    if $?.to_i == 0
      puts "rating before = #{self.rating}"
      puts "rating after = #{x}"

      new_rating = eval(x).round(2)
      color_rating = new_rating.round_down(1)

      update_columns(rating: new_rating)
      update_historical_avg_rating

      if a > 1.0
        update_columns(color_rating: color_rating)        
        update_popularity_rank
      else
        update_columns(color_rating: -1.0)
        update_columns(popularity_rank: 0.0)
      end

      update_columns(latest_rating_update_time: Time.now)
    else
      puts "Could not calculate rating. Status: #{$?.to_i}"
    end
  end

  def update_historical_avg_rating
    tz_offset = time_zone_offset || 0.0
    current_hour = (Time.now.utc + tz_offset.hours).hour.to_i
    ratings_hash = self.hist_rating_avgs
    key = "hour_#{current_hour}"
    count = ratings_hash[key]["count"]
    previous_hist_rating = ratings_hash[key]["rating"]    
    current_rating = rating || 0
    updated_hist_rating = (previous_hist_rating * count.to_f + current_rating) / (count.to_f + 1.0)
    ratings_hash[key]["count"] = count + 1
    ratings_hash[key]["rating"] = updated_hist_rating
    self.update_columns(hist_rating_avgs: ratings_hash)
  end

  #A. Trend Scoring------------------------------------------------------------------
  #---------------------------------------------------------------------------------- 
  def update_popularity_rank
    view_half_life = 60.0 #minutes
    latest_page_view_time_wrapper = latest_page_view_time || Time.now
    new_page_view_count = (self.page_views * 2 ** ((-(Time.now - latest_page_view_time_wrapper)/60.0) / (view_half_life))).round(4)
    self.update_columns(page_views: new_page_view_count)
    tz_offset = self.time_zone_offset || 0.0
    current_hour = (Time.now.utc + tz_offset.hours).hour.to_i
    key = "hour_#{current_hour}"
    historical_rating = self.hist_rating_avgs[key]["rating"]
    current_rating = rating || 0
    k = 0.8
    m = 0.01
    e = 0.2
    new_popularity_rank = (current_rating + (current_rating - historical_rating)*k) + new_page_view_count*m + event_happening?*e
    self.update_columns(popularity_rank: new_popularity_rank)
  end

  def account_page_view(u_id, is_favorite="0")
    view_half_life = 120.0 #minutes
    latest_page_view_time_wrapper = latest_page_view_time || Time.now
    new_page_view_count = (self.page_views * 2 ** ((-(Time.now - latest_page_view_time_wrapper)/60.0) / (view_half_life))).round(4)+1.0

    self.update_columns(page_views: new_page_view_count)
    self.update_columns(latest_page_view_time: Time.now)
    FeedUser.joins(feed: :feed_venues).where("venue_id = ?", self.id).each{|feed_user| feed_user.update_interest_score(0.05)}

    if is_favorite == "1"
      favorite_venue = FavoriteVenue.find_by_user_id_and_venue_id(u_id, self.id)
      favorite_venue.num_new_moments_for_user if favorite_venue != nil#if (favorite_venue.latest_check_time == nil or favorite_venue.latest_check_time < Time.now - 15.minutes)
    end
  end  



#===============================================================================================
# Attributes ===================================================================================
#===============================================================================================
  def partial
    {"address" => address, "city" => city, "state" => state, "country" => country, "postal_code" => postal_code, "latitude" => latitude, "longitude" => longitude}
  end

  def add_foursquare_details
    if self.foursquare_id == nil      
      foursquare_venue = Venue.foursquare_venue_lookup(self.name, self.latitude, self.longitude, self.city)
      if foursquare_venue != nil && foursquare_venue != "F2 ERROR"        
        venue_foursquare_id = foursquare_venue.id
        self.update_columns(foursquare_id: venue_foursquare_id)
      else
        puts "Encountered Error"
        return nil
      end
    end
    
    client = Foursquare2::Client.new(:client_id => '35G1RAZOOSCK2MNDOMFQ0QALTP1URVG5ZQ30IXS2ZACFNWN1', :client_secret => 'ZVMBHYP04JOT2KM0A1T2HWLFDIEO1FM3M0UGTT532MHOWPD0', :api_version => '20120610')
    foursquare_venue_with_details = client.venue(foursquare_id) rescue "F2 ERROR"
    if foursquare_venue_with_details != "F2 ERROR"
      set_categories_and_descriptives(foursquare_venue_with_details)
      set_hours(foursquare_venue_with_details)

      if self.address == nil
        self.update_columns(address: foursquare_venue_with_details.location.address)
        self.update_columns(postal_code: foursquare_venue_with_details.location.postalCode)
        self.update_columns(state: foursquare_venue_with_details.location.state)
      end
    end
  end

  def update_descriptives_from_instagram(instagram_hash) 
    caption = instagram_hash["caption"]["text"] rescue ""
    #tags = instagram_hash["tags"].join(" ").strip

    if caption.length > 0
      update_descriptives(caption)
    end
  end

  def set_categories_and_descriptives(foursquare_venue)
    f2_categories = foursquare_venue.categories
    categories_hash = {}
    categories_string = ""

    i = 1
    for category in f2_categories
      if category.primary == true
        categories_hash["category_1"] = category.name
        categories_string.concat(" "+category.name)
      else
        categories_hash["category_#{i}"] = category.name
        categories_string.concat(category.name)
      end
      i += 1
    end

    self.update_columns(categories: categories_hash)
    self.update_columns(categories_string: categories_hash.keys.join(" ").strip)

    f2_tags = foursquare_venue.tags
    update_descriptives(f2_tags.join(" ").strip)
  end

  def add_category(category)
    categories_hash = self.categories
    num_categories = categories_hash.count
    if categories_hash.values.include? category == false
      categories_hash["category_#{num_categories+1}"] = category
      self.update_columns(categories: categories_hash)
      self.update_columns(categories_string: categories_hash.values.join(" ").strip)
    end
  end

  def update_descriptives(new_descriptives_string)
    new_descriptives_string.gsub!(/\B[@#]\S+\b/, '').try(:downcase!).try(:strip)
    #check spelling
    if new_descriptives_string != nil && new_descriptives_string != "" && (new_descriptives_string.include?("__") == false)
      begin
        spell_checker = Gingerice::Parser.new
        new_descriptives_string = spell_checker.parse(new_descriptives_string)["result"]
      rescue
        p "Spell checker failed to start"
      end

      #remove occurances of the venue name and city (their occurnace carries little value)
      #as well as some other stop words.
      new_descriptives_string.gsub(self.name.downcase, "").try(:strip)
      new_descriptives_string.gsub(self.name.downcase.gsub(" ", ""), "").try(:strip)
      if self.city != nil
        new_descriptives_string.gsub(self.city.downcase, "").try(:strip)
        new_descriptives_string.gsub(self.city.downcase.gsub(" ", ""), "").try(:strip)
      end

      if new_descriptives_string != nil && new_descriptives_string != ""
        #extract nouns
        text_tagger = EngTagger.new
        descriptives_tagged = text_tagger.get_nouns(text_tagger.add_tags(new_descriptives_string))
        if descriptives_tagged != nil
          descriptive_nouns = descriptives_tagged.keys
          if descriptive_nouns.count > 0
            singularized = []
            descriptive_nouns.each{|noun| singularized << noun.singularize}

            #Trending words analysis
            breakdown = Highscore::Content.new singularized.join(" ")
              breakdown.configure do
                set :long_words_threshold, 15
                set :short_words_threshold, 3
                set :ignore_case, true
              end

            top_key_words = breakdown.keywords.top(10)

            descriptives_hash = self.descriptives
            key_word_relevance_half_life = 120 #minutes
            for key_word in top_key_words
              if descriptives_hash[key_word.text] != nil
                previous_weight = descriptives_hash[key_word.text]["weight"].to_f
                previous_num_posts = descriptives_hash[key_word.text]["num_posts"] || 1
                new_weight = ( ((previous_weight * 2 ** ((-(Time.now - descriptives_hash[key_word.text]["updated_at"].to_datetime)/60.0) / (key_word_relevance_half_life)).round(4)) * previous_num_posts + key_word.weight.to_f) / (previous_num_posts + 1)).round(2)
                if new_weight < 1.0
                  descriptives_hash.delete(key_word.text)
                else
                  descriptives_hash[key_word.text]["weight"] = new_weight
                  descriptives_hash[key_word.text]["updated_at"] = Time.now
                  descriptives_hash[key_word.text]["num_posts"] = previous_num_posts + 1
                end
              else
                descriptives_hash[key_word.text] = {"weight" => key_word.weight, "updated_at" => Time.now, "num_posts" => 1}
              end
            end

            self.update_columns(descriptives: descriptives_hash)
            self.update_columns(descriptives_string: descriptives_hash.keys.join(" ").strip)
          end
        end
      end
    end
  end

  def calibrate_descriptive_weights
    descriptives_hash = self.descriptives
    key_word_relevance_half_life = 120 #minutes
    if descriptives_hash.length > 0
      descriptives_hash.each do |descriptive, details|
        previous_weight = details["weight"].to_f
        new_weight = previous_weight * 2 ** ((-(Time.now - details["updated_at"].to_datetime)/60.0) / (key_word_relevance_half_life)).round(2)
        if new_weight.round(2) < 1.0  
          descriptives_hash.delete(descriptive)
        else
          descriptives_hash[descriptive]["weight"] = new_weight
          descriptives_hash[descriptive]["updated_at"] = Time.now
        end
      end
    end
    self.update_columns(descriptives: Hash[descriptives_hash.sort_by { |k,v| -v["weight"] }])
  end

  def set_top_tags
    calibrate_descriptive_weights
    top_descriptives = Hash[self.descriptives.to_a[0..4]]

    tags_hash = {}
    i = 1
    top_descriptives.each do |descriptive, details|
      if details["weight"].round(2) > 0.0
        tags_hash["tag_#{i}"] = descriptive        
      else
        tags_hash["tag_#{i}"] = nil
      end
      i += 1
    end

    self.update_columns(trending_tags: tags_hash)
  end  

  def update_featured_comment(vc)
    trending_tags = self.trending_tags
    self_partial = self.partial
    self_partial["trending_tags"] = trending_tags

    if vc.entry_type == "tweet"
      venue_featured_activity = Activity.where("venue_id = ? AND activity_type = ?", self.id, "featured_venue_tweet").first
      if venue_featured_activity == nil
        venue_featured_activity = Activity.create!(:activity_type => "featured_venue_tweet", :venue_id => self.id, :venue_details => self_partial, 
          :venue_comment_details => vc.to_json, :adjusted_sort_position => vc.tweet[:created_at].to_i)
      else
        if vc.tweet[:created_at].to_i > venue_featured_activity.venue_comment_details["adjusted_sort_position"].to_i
          venue_featured_activity.update_columns(venue_comment_details: vc.to_json)
          venue_featured_activity.update_columns(adjusted_sort_position: vc.tweet[:created_at].to_i)
        end
      end      
    else
      venue_featured_activity = Activity.where("venue_id = ? AND activity_type = ?", self.id, "featured_venue_post").first
      vc_created_at = vc.lytit_post["created_at"] or vc.instagram["created_at"]
      if venue_featured_activity == nil        
        venue_featured_activity = Activity.create!(:activity_type => "featured_venue_post", :venue_id => self.id, :venue_details => self_partial, 
          :venue_comment_details => vc.to_json, :adjusted_sort_position => vc_created_at.to_i)
      else
        if vc.adjusted_sort_position > venue_featured_activity.venue_comment_details["adjusted_sort_position"].to_i
          venue_featured_activity.update_columns(venue_comment_details: vc.to_json)
          venue_featured_activity.update_columns(adjusted_sort_position: vc_created_at)
        end
      end
      self.update_columns(venue_comment_details: vc.to_json)      
    end
    
  end

  def last_post_time
    if latest_posted_comment_time != nil
      (Time.now - latest_posted_comment_time)
    else
      nil
    end
  end

  def Venue.last_post_time(time)
    if time != nil && time != ""
      (Time.now-time.to_datetime).to_i
    else
      0
    end
  end

  def event_happening?
    self.events.where("start_time >= ? AND end_time <= ?", Time.now, Time.now).any? ? 1:0
  end

#===============================================================================================
# Validation ===================================================================================
#===============================================================================================
  def Venue.validate_venue(venue_name, venue_lat, venue_long, venue_instagram_location_id, origin_vortex)
    #Used to establish if a location tied to an Instagram is legitimate and not a fake, "Best Place Ever" type one.
    #Returns a venue object if location is valid, otherwise nil. Primary check occurs through a Froursquare lookup.
    excluded_venue_types = ["States & Municipalities", "City", "County", "Country", "Neighborhood", "State", "Town", "Village"]

    if venue_name != nil and Venue.name_is_proper?(venue_name)
      #Search for venue in Lytit DB
      lytit_venue_lookup = Venue.fetch_venues_for_instagram_pull(venue_name, venue_lat, venue_long, venue_instagram_location_id, origin_vortex)

      if lytit_venue_lookup == nil
        #Venue not found so need to check if venue is valid and create a new entry if so.

        foursquare_venue = Venue.foursquare_venue_lookup(venue_name, venue_lat, venue_long, origin_vortex.city)
          #no corresponding venue found in Foursquare database
        if foursquare_venue == nil || foursquare_venue == "F2 ERROR"
          return nil
        elsif foursquare_venue.categories.first.try(:name) != nil and excluded_venue_types.include?(foursquare_venue.categories.first.name) == true
            return nil
        else
          #for major US cities we only deal with verified venues
          major_countries = ["United States"]
          if major_countries.include? origin_vortex.country == true && foursquare_venue.verified == false
            return nil
          else
            #Creating new entry.
            new_lytit_venue = Venue.create_new_db_entry(foursquare_venue.name, foursquare_venue.location.address, origin_vortex.city, foursquare_venue.location.state, origin_vortex.country, foursquare_venue.location.postalCode, nil, venue_lat, venue_long, venue_instagram_location_id, origin_vortex)
            new_lytit_venue.update_columns(foursquare_id: foursquare_venue.id)
            new_lytit_venue.update_columns(verified: true)
            new_lytit_venue.add_foursquare_details            
            InstagramLocationIdLookup.delay.create!(:venue_id => new_lytit_venue.id, :instagram_location_id => venue_instagram_location_id)
            return new_lytit_venue
          end
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

  def Venue.name_for_comparison(raw_venue_name, city)
    scrubbed_name = Venue.scrub_venue_name(raw_venue_name, city)
    stop_word_cleared_name = Venue.clear_stop_words(scrubbed_name)
  end

  def Venue.scrub_venue_name(raw_name, city)
    #Many Instagram names are contaminated with extra information inputted by the user, i.e "Concert @ Madison Square Garden"
    if raw_name != nil && city != nil
      lower_raw_name = raw_name.downcase 
      lower_city = city.downcase

      if lower_raw_name.include?(" @ ") == true
        lower_raw_name = lower_raw_name.partition(" @ ").last.strip
      end

      if lower_raw_name.include?("@ ") == true
        lower_raw_name = lower_raw_name.partition("@ ").last.strip
      end

      if lower_raw_name.include?(" @") == true
        lower_raw_name = lower_raw_name.partition(" @").last.strip
      end

      if lower_raw_name.include?("@") == true
        lower_raw_name = lower_raw_name.partition("@").last.strip
      end      

      if lower_raw_name.include?(" at ") == true
        lower_raw_name = lower_raw_name.partition(" at ").last.strip.capitalize
      end

      if (lower_city != nil && lower_city != "" && lower_city != " ") and (lower_raw_name.include?("#{lower_city}") == true && lower_raw_name.index("#{lower_city}") != 0)
        lower_raw_name = lower_raw_name.partition("#{lower_city}").first.strip
      end

      clean_name = lower_raw_name.titleize
      return clean_name || raw_name
    else
      raw_name
    end
  end

  def Venue.clear_stop_words(venue_name)
    lower_venue_name = venue_name.downcase
    stop_words = ["the", "a", "cafe", "café", "restaurant", "club", "bar", "hotel", "downtown", "updtown", "midtown", "park", "national", "of", "at", "university", ",", "."]
    pattern = /\b(?:#{ Regexp.union(stop_words).source })\b/    
    lower_venue_name[pattern]
    lower_venue_name.gsub(pattern, '').squeeze(' ').strip.titleize
  end

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
    elsif (vname.downcase.include? "|") || (vname.downcase.include? "#") || (vname.downcase.include? ";") || (vname.downcase.include? "/")
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


#===============================================================================================
# Calibration ==================================================================================
#===============================================================================================

  #A. Business/Popular Hours---------------------------------------------------------
  #----------------------------------------------------------------------------------
  def set_hours(foursquare_venue_with_details=nil)
    venue_foursquare_id = self.foursquare_id

    if venue_foursquare_id == nil      
      foursquare_venue = Venue.foursquare_venue_lookup(name, self.latitude, self.longitude, self.city)
      if foursquare_venue != nil && foursquare_venue != "F2 ERROR"        
        venue_foursquare_id = foursquare_venue.id
        self.update_columns(foursquare_id: venue_foursquare_id)
      else
        if foursquare_venue == "F2 ERROR"
          puts "Encountered Error"
          return {}
        else
          self.update_columns(open_hours: {"NA"=>"NA"})
          return open_hours
        end
      end
    end

    if venue_foursquare_id != nil
      if foursquare_venue_with_details == nil
        client = Foursquare2::Client.new(:client_id => '35G1RAZOOSCK2MNDOMFQ0QALTP1URVG5ZQ30IXS2ZACFNWN1', :client_secret => 'ZVMBHYP04JOT2KM0A1T2HWLFDIEO1FM3M0UGTT532MHOWPD0', :api_version => '20120610')
        foursquare_venue_with_details = client.venue(venue_foursquare_id) rescue "F2 ERROR"
      end
      
      if foursquare_venue_with_details == "F2 ERROR"
        puts "Encountered Error"
        return {}
      end
      if foursquare_venue_with_details != nil
        fq_open_hours = foursquare_venue_with_details.hours #|| foursquare_venue_with_details.popular
        fq_popular_hours = foursquare_venue_with_details.popular

        self.set_open_hours(fq_open_hours)
        self.set_popular_hours(fq_popular_hours)

        #we set the category and descriptives here to preserve
        #api calls (foursquare venue is already pulled in)
        self.set_categories_and_descriptives(foursquare_venue_with_details)
      else
        self.update_columns(open_hours: {"NA"=>"NA"})
        self.update_columns(popular_hours: {"NA"=>"NA"})
      end
    else
      self.update_columns(open_hours: {"NA"=>"NA"})
      self.update_columns(popular_hours: {"NA"=>"NA"})
    end
    return open_hours
  end

  def set_open_hours(fq_open_hours)
    if fq_open_hours != nil
      open_hours_hash = Hash.new
      timeframes = fq_open_hours.timeframes
      utc_offset_hours = self.time_zone_offset || 0.0

      for timeframe in timeframes
        if timeframe.open.first.renderedTime != "None"
          days = Venue.create_days_array(timeframe.days, utc_offset_hours)
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
      end
      self.update_columns(open_hours: open_hours_hash)
    else
      self.update_columns(open_hours: {"NA"=>"NA"})
    end          
  end

  def set_popular_hours(fq_popular_hours)
    if fq_popular_hours != nil
      popular_hours_hash = Hash.new
      timeframes = fq_popular_hours.timeframes
      utc_offset_hours = self.time_zone_offset || 0.0

      for timeframe in timeframes
        if timeframe.open.first.renderedTime != "None"    
          days = Venue.create_days_array(timeframe.days, utc_offset_hours)
          for day in days
            popular_spans = timeframe.open
            span_hash = Hash.new
            i = 0
            for span in popular_spans            
              frame_hash = Hash.new
              open_close_array = Venue.convert_span_to_minutes(span.renderedTime)                      
              frame_hash["frame_"+i.to_s] = {"start_time" => open_close_array.first, "end_time" => open_close_array.last}            
              span_hash.merge!(frame_hash)
              i += 1
            end
            popular_hours_hash[day] = span_hash
          end
        end
      end
      self.update_columns(popular_hours: popular_hours_hash)
    else
      self.update_columns(popular_hours: {"NA"=>"NA"})
    end    
  end

  def Venue.create_days_array(timeframe_days, venue_utc_offset)
    days = Hash.new
    days["Mon"] = 1
    days["Tue"] = 2
    days["Wed"] = 3
    days["Thu"] = 4
    days["Fri"] = 5
    days["Sat"] = 6
    days["Sun"] = 7

    days_array = []

    split_timeframe_days = timeframe_days.split(",")

    for timeframe in split_timeframe_days
      timeframe.strip!
      if timeframe.include?("–")
        #Indicates a range of dates 'Mon-Sun'
        timeframe_array = timeframe.split("–")
        commence_day = timeframe_array.first
        end_day = timeframe_array.last
        if days[commence_day] != nil && days[end_day] != nil
          [*days[commence_day]..days[end_day]].each{|day_num| days_array << days.key(day_num)}
        end
      else
        #Single day timeframe, i.e 'Mon'
        if timeframe == "Today"
          timeframe =  Date::ABBR_DAYNAMES[(Time.now.utc+venue_utc_offset.hours).wday]
        end
        days_array << timeframe
      end
    end
    return days_array
  end

  def Venue.convert_span_to_minutes(span)
    span_array=span.split("–")
    opening = span_array.first
    closing = span_array.last

    if opening == "24 Hours"
      opening_time = 0.0
      closing_time = 0.0
    else
      if opening.last(2) == "AM"
        opening_time = opening.split(" ").first.gsub(":",".").to_f
      elsif opening == "Midnight"
        opening_time = 0.0
      elsif opening == "Noon"
        opening_time = 12.0      
      else
        opening_time = opening.split(" ").first.gsub(":",".").to_f+12.0
      end

      if closing.last(2) == "PM"
        closing_time = closing.split(" ").first.gsub(":",".").to_f+12.0
      elsif closing == "Midnight"
        closing_time = 0.0
      elsif closing == "Noon"
        closing_time = 12.0
      else
        if opening.last(2) == "PM"
          closing_time = closing.split(" ").first.gsub(":",".").to_f+24.0
        else
          closing_time = closing.split(" ").first.gsub(":",".").to_f
        end
      end
    end

    return [opening_time, closing_time]
  end

  def in_timespan?(hour_type, date_time)
    if hour_type == "open_hours"
      hour_type = self.open_hours
      t_0 = "open_time"
      t_n = "close_time"
    else
      hour_type = self.popular_hours
      t_0 = "start_time"
      t_n = "end_time"
    end

    in_timespan = nil
    if hour_type == {} || hour_type == {"NA"=>"NA"}
      in_timespan = true   
    else
      utc_offset = self.time_zone_offset || 0.0
      local_time = date_time.utc.hour.to_f+date_time.utc.min.to_f/100.0+utc_offset
      if local_time < 0 
        #utc is ahead of local time
        local_time += 24
      end
      today = Date::ABBR_DAYNAMES[(date_time.utc+utc_offset.hours).wday]
      today_time_spans = hour_type[today]
      yesterday = Date::ABBR_DAYNAMES[(date_time.utc+utc_offset.hours).wday-1]
      yesterday_time_spans = hour_type[yesterday]

      if today_time_spans == nil
        if yesterday_time_spans != nil
          if yesterday_time_spans.values.last[t_n] > 24.0 && (yesterday_time_spans.values.last[t_n] - 24.0) >= local_time
            today_time_spans = yesterday_time_spans
            frames = yesterday_time_spans.values
          else
            in_timespan = false
          end
        else
          in_timespan = false
        end
      else
        frames = today_time_spans.values
        if frames.last[t_n].to_i == 0.0
          close_time = 24.0
        else
          close_time = frames.last[t_n]
        end

        #if the post is coming in at 2:00 in the morning we have to look at the previous days business hours (applicable to nightlife establishments)
        if (close_time > 24.0 && (close_time - 24.0) >= local_time)
          yesterday = Date::ABBR_DAYNAMES[(date_time.utc+utc_offset.hours).wday-1]
          if hour_type[yesterday] != nil
            frames = hour_type[yesterday].values
          else
            in_timespan = false
          end
        end
      end

      if in_timespan == nil
        for frame in frames
          open_time = frame[t_0]
 
          if frame[t_n].to_i == 0.0
            close_time = 24.0
          else
            close_time = frame[t_n]
          end

          if (close_time > 24.0 && (close_time - 24.0) >= local_time)
            time_range = (((date_time.utc+utc_offset.hours) - (date_time.utc+utc_offset).hour.hour - (date_time.utc+utc_offset).min.minutes) - (24.0-open_time).hours).to_i..(((date_time.utc+utc_offset) - (date_time.utc+utc_offset).hour.hour - (date_time.utc+utc_offset).min.minutes) + close_time.hours).to_i
          else
            time_range = (((date_time.utc+utc_offset.hours).utc - (date_time.utc+utc_offset.hours).utc.hour.hour - (date_time.utc+utc_offset.hours).utc.min.minutes) + open_time.hours).to_i..(((date_time.utc+utc_offset.hours).utc - (date_time.utc+utc_offset.hours).utc.hour.hour - (date_time.utc+utc_offset.hours).utc.min.minutes) + close_time.hours).to_i
          end

          in_timespan = (time_range === (date_time.utc+utc_offset.hours).to_i)
          if in_timespan == true
            break
          end
        end
      end
    end
    return in_timespan
  end  

  def is_open?
    in_timespan?("open_hours", Time.now)
  end
  
  def is_popular?
    if open_hours == {}
      self.set_hours
    end
    in_timespan?("popular_hours", Time.now)
  end  

  #B. Time Zones --------------------------------------------------------------------
  #----------------------------------------------------------------------------------
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
      self.update_columns(time_zone: origin_vortex.time_zone)
      self.update_columns(time_zone_offset: origin_vortex.time_zone_offset)
      #Set nearest instagram vortex id if a vortex within 10kms present
      radius  = 10000
      #nearest_vortex = InstagramVortex.within(radius.to_i, :units => :kms, :origin => [self.latitude, self.longitude]).order('distance ASC').first
      search_box = Geokit::Bounds.from_point_and_radius([self.latitude, self.longitude], radius.to_i, :units => :kms)
      closest_vortex = InstagramVortex.in_bounds(search_box).order("id ASC").first
      self.update_columns(instagram_vortex_id: closest_vortex.id)
    end
  end

  def Venue.fill_in_time_zone_offsets
    radius  = 10000
    for venue in Venue.all.where("time_zone_offset IS NULL")
      search_box = Geokit::Bounds.from_point_and_radius([lat,long], radius.to_i, :units => :kms)
      closest_vortex = InstagramVortex.in_bounds(search_box).order("id ASC").first
      #closest_vortex = InstagramVortex.within(radius.to_i, :units => :kms, :origin => [venue.latitude, venue.longitude]).where("time_zone_offset IS NOT NULL").order('distance ASC').first
      venue.update_columns(time_zone_offset: closest_vortex.time_zone_offset)
    end
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

  def Venue.calibrate_venues_after_daylight_savings
    for vortex in InstagramVortex.all
      p "Vortex: #{vortex.city}"
      vortex.set_timezone_offsets
      radius = 10#km
      vortex_venues = Venue.close_to(vortex.latitude, vortex.longitude, radius*1000)
      vortex_venues.update_all(instagram_vortex_id: vortex.id)
      vortex_venues.update_all(time_zone: vortex.time_zone)
      vortex_venues.update_all(time_zone_offset: vortex.time_zone_offset)
    end
  end

  #B. Address and Telephone ---------------------------------------------------------
  #----------------------------------------------------------------------------------
  def calibrate_attributes(auth_name, auth_address, auth_city, auth_state, auth_country, auth_postal_code, auth_phone, auth_latitude, auth_longitude)
    #We calibrate with regards to the Apple Maps database
    auth_city = auth_city.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n,'').to_s rescue nil#Removing accent marks
    #Name
    if self.name != auth_name
      self.name = auth_name
    end

    #Address
    if (self.city == nil || self.state == nil || self.city = "" || self.city = ' ') or (self.city != auth_city) #Add venue details if they are not present
      self.update_columns(formatted_address: Venue.address_formatter(address, city, state, postal_code, country))
      self.update_columns(city: auth_city)
      self.update_columns(state: auth_state)
      self.update_columns(country: auth_country) 

      if auth_phone != nil
        self.phone_number = Venue.formatTelephone(auth_phone)
      end
      self.save
    end

    if self.address == nil && (auth_address != nil && auth_address != "")
      self.update_columns(address: auth_address)
    end

    #Geo
    if auth_latitude != nil and self.latitude != auth_latitude
      self.latitude = auth_latitude
    end

    if auth_longitude != nil and self.longitude != auth_longitude
      self.longitude = auth_longitude
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

#===============================================================================================
# Helpers ======================================================================================
#===============================================================================================
  def details_missing?
    if foursquare_id == nil || (address == nil && state == nil) || (open_hours == {} && popular_hours == {}) || (categories == {} && descriptives == {})
      true
    else
      false
    end
  end

  def partial
    {:id => self.id, :name => self.name, :address => self.address, :city => self.city, :state => self.state, :country => self.country, :latitude => self.latitude, :longitude => self.longitude}
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

  def self.spherecial_distance_between_points(lat_1, long_1, lat_2, long_2)
    result = Geocoder::Calculations.distance_between([lat_1, long_1], [lat_2, long_2], :units => :km)
    if result >= 0.0
      result
    else
      1000.0
    end
  end  

#===============================================================================================
# Actions ======================================================================================
#===============================================================================================
def Venue.live_recommendation_for(user, lat=40.741140, long=-73.981917)
  top_user_interests = user.top_interests(6)
  search_box = Geokit::Bounds.from_point_and_radius([lat, long], 5, :units => :kms)
  
  if top_user_interests.count > 0
    interest_query = top_user_interests.join(" ")
 
    user_feed_ids = "SELECT feed_id FROM feed_users WHERE user_id = #{user.id}"
    user_feed_venues = "SELECT venue_id FROM feed_venues WHERE feed_id IN (#{user_feed_ids})"

    results = Venue.in_bounds(search_box).order("popularity_rank DESC").interest_search(interest_query).where("popularity_rank > 0.0").limit(30)

    if results.length == 0
      results = Venue.in_bounds(search_box).order("popularity_rank DESC").where("color_rating > -1.0").limit(30)  
    end
  else
    results = Venue.in_bounds(search_box).order("popularity_rank DESC").where("color_rating > -1.0").limit(30)  
  end

  return results
end

def recommendation_reason_for(user)
  if user.interests = {}
    return "Active around you"
  else
    user_list = user.feeds.joins(:feed_venues).where("venue_id = ?", self.id).first

    if user_list != nil
      return "Part of #{user_list.name}"
    else
      top_user_interests = user.top_interests(6)
      interest_match = Venue.interest_search(top_user_interests.join(" ")).where("id = ?", self.id).first != nil

      if interest_match == true
        for interest in top_user_interests
          if Venue.interest_search(interest).where("id = ?", self.id).first != nil
            details = user.interests["descriptives"][interest] || user.interests["venue_categories"][interest]
            if details["searched_venue_ids"] != nil
              return "Similar to venues searched for"
            elsif details["favorite_venue_ids"] != nil
              return "Based on your favorites"
            else
              return "Based on your List interests"
            end    
          end
        end
      end
    end
  end
end


#===============================================================================================
# Cleanups =====================================================================================
#===============================================================================================
  def Venue.clear_geographies
    excluded_venue_types = ["States & Municipalities", "City", "County", "Country", "Neighborhood", "State", "Town", "Village"]
    for excluded_venue_type in excluded_venue_types
       Venue.all.where("categories ->> 'category_1' = ? OR categories ->> 'category_2' = ? OR categories ->> 'category_3' = ?", excluded_venue_type, excluded_venue_type, excluded_venue_type).delete_all 
    end
  end

  def Venue.clear_dupe_venues(city)
    pre_dupe_clear_count = Venue.where("city = ?",city).count
    feed_venue_ids = "SELECT venue_id FROM feed_venues"
    favorite_venue_ids = "SELECT venue_id FROM favorite_venues"
    dupes = Venue.where("city = ?", city).select([:name,:city]).group(:name,:city).having("count(*) > 1")
    for dupe in dupes
      p"Venue: #{dupe.name} IN #{dupe.city}"
      dupe_venues = Venue.where("name = ? AND city = ? AND ID NOT IN (#{feed_venue_ids}) AND ID NOT IN (#{favorite_venue_ids})", dupe.name, dupe.city)

      dupe_venues.delete_all
    end
    after_dupe_clear_count = Venue.where("city = ?",city).count
    p "Num dupes cleared: #{pre_dupe_clear_count-after_dupe_clear_count}"
  end

  def Venue.database_cleanup_nulls
    #cleanup venue database by removing garbage/unused venues. This is necessary in order to manage
    #database size and improve searching/lookup performance. 
    #Keep venues that fit following criteria:
    #1. Venue is in a List
    #2. Venue has been Bookmarked
    #3. Venue is an Apple verified venue (address != nil, city != nil)
    #4. Venue CURRENTLY has a color rating
    #5. Venue has been posted at in the past 3 days
    num_venues_before_cleanup = Venue.all.count

    days_back = num_days_back || 3
    feed_venue_ids = "SELECT venue_id FROM feed_venues"
    favorite_venue_ids = "SELECT venue_id FROM favorite_venues"
    criteria = "latest_posted_comment_time IS NULL AND venues.id NOT IN (#{feed_venue_ids}) AND venues.id NOT IN (#{favorite_venue_ids}) AND (address is NULL OR city = ?) AND color_rating < 0"

    InstagramLocationIdLookup.all.joins(:venue).where(criteria, "").delete_all
    p "Associated Inst Location Ids Cleared"    
    VenueComment.all.joins(:venue).where(criteria, "").delete_all
    p "Associated Venue Comments Cleared"    
    MetaData.all.joins(:venue).where(criteria, "").delete_all
    p "Associated Meta Data Cleared"
    Tweet.all.joins(:venue).where(criteria, "").delete_all
    p "Associated Tweets Cleared"
    LytitVote.all.joins(:venue).where(criteria, "").delete_all
    p "Associated Lytit Votes Cleared"
    LytSphere.all.joins(:venue).where(criteria, "").delete_all
    p "Associated Lyt Spheres Cleared"
    VenuePageView.all.joins(:venue).where(criteria, "").delete_all
    p "Associated Venue Page Views Cleared"

    Venue.where("latest_posted_comment_time IS NULL AND id NOT IN (#{feed_venue_ids}) AND id NOT IN (#{favorite_venue_ids}) AND (address is NULL OR city = ?) AND color_rating < 0", '').delete_all
    p "Venues Cleared"
    num_venues_after_cleanup = Venue.all.count

    p"Venue Database cleanup complete! Venue Count Before: #{num_venues_before_cleanup}. Venue Count After: #{num_venues_after_cleanup}. Total Cleared: #{num_venues_before_cleanup - num_venues_after_cleanup}"
  end  


  def Venue.database_cleanup(num_days_back=nil)
    #cleanup venue database by removing garbage/unused venues. This is necessary in order to manage
    #database size and improve searching/lookup performance. 
    #Keep venues that fit following criteria:
    #1. Venue is in a List
    #2. Venue has been Bookmarked
    #3. Venue is an Apple verified venue (address != nil, city != nil)
    #4. Venue CURRENTLY has a color rating
    #5. Venue has been posted at in the past 3 days
    num_venues_before_cleanup = Venue.all.count

    days_back = num_days_back || 3
    feed_venue_ids = "SELECT venue_id FROM feed_venues"
    favorite_venue_ids = "SELECT venue_id FROM favorite_venues"
    criteria = "latest_posted_comment_time < ? AND venues.id NOT IN (#{feed_venue_ids}) AND venues.id NOT IN (#{favorite_venue_ids}) AND (address is NULL OR city = ?) AND color_rating < 0"

    InstagramLocationIdLookup.all.joins(:venue).where(criteria, Time.now - days_back.days, "").delete_all
    p "Associated Inst Location Ids Cleared"    
    VenueComment.all.joins(:venue).where(criteria, Time.now - days_back.days, "").delete_all
    p "Associated Venue Comments Cleared"    
    MetaData.all.joins(:venue).where(criteria, Time.now - days_back.days, "").delete_all
    p "Associated Meta Data Cleared"
    Tweet.all.joins(:venue).where(criteria, Time.now - days_back.days, "").delete_all
    p "Associated Tweets Cleared"
    LytitVote.all.joins(:venue).where(criteria, Time.now - days_back.days, "").delete_all
    p "Associated Lytit Votes Cleared"
    LytSphere.all.joins(:venue).where(criteria, Time.now - days_back.days, "").delete_all
    p "Associated Lyt Spheres Cleared"
    VenuePageView.all.joins(:venue).where(criteria, Time.now - days_back.days, "").delete_all
    p "Associated Venue Page Views Cleared"

    Venue.where("latest_posted_comment_time < ? AND id NOT IN (#{feed_venue_ids}) AND id NOT IN (#{favorite_venue_ids}) AND (address is NULL OR city = ?) AND color_rating < 0", Time.now - days_back.days, '').delete_all
    p "Venues Cleared"
    num_venues_after_cleanup = Venue.all.count

    p"Venue Database cleanup complete! Venue Count Before: #{num_venues_before_cleanup}. Venue Count After: #{num_venues_after_cleanup}. Total Cleared: #{num_venues_before_cleanup - num_venues_after_cleanup}"
  end

  def Venue.recalibrate_all_rankings
    Venue.update_all(rating: nil)
    Venue.update_all(color_rating: -1.0)
    Venue.update_all(r_up_votes: 1.0)
    clean_history = {:hour_1=>{:rating=> 0, :count => 0}, 
    :hour_2=>{:rating=> 0, :count => 0}, :hour_3=>{:rating=> 0, :count => 0}, :hour_4=>{:rating=> 0, :count => 0},
    :hour_5=>{:rating=> 0, :count => 0}, :hour_6=>{:rating=> 0, :count => 0},
    :hour_7=>{:rating=> 0, :count => 0}, :hour_8=>{:rating=> 0, :count => 0}, :hour_9=>{:rating=> 0, :count => 0},
    :hour_10=>{:rating=> 0, :count => 0}, :hour_11=>{:rating=> 0, :count => 0}, :hour_12=>{:rating=> 0, :count => 0},
    :hour_13=>{:rating=> 0, :count => 0}, :hour_14=>{:rating=> 0, :count => 0}, :hour_15=>{:rating=> 0, :count => 0},
    :hour_16=>{:rating=> 0, :count => 0}, :hour_17=>{:rating=> 0, :count => 0}, :hour_18=>{:rating=> 0, :count => 0},
    :hour_19=>{:rating=> 0, :count => 0}, :hour_20=>{:rating=> 0, :count => 0}, :hour_21=>{:rating=> 0, :count => 0},
    :hour_22=>{:rating=> 0, :count => 0}, :hour_23=>{:rating=> 0, :count => 0}, :hour_0=>{:rating=> 0, :count => 0}}
    Venue.update_all(hist_rating_avgs: clean_history)
    Venue.update_all(popularity_rank: 0.0)
  end





######################################
#                                    #
#    ########  ########  ########    #
#    ########  ########  ########    #
#    ##    ##  ##    ##     ##       #
#    ########  ########     ##       #
#    ##    ##  ##        ########    #
#    ##    ##  ##        ########    #
#                                    #
######################################


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Instagram #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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

    if self.name.downcase.include?("university") || self.name.downcase.include?("park")
      wide_area_search = true
      nearby_instagram_content = Instagram.media_search(latitude, longitude, :distance => 200, :count => 100)
    else
      #Dealing with an establishment so can afford a smaller pull radius.
      nearby_instagram_content = Instagram.media_search(latitude, longitude, :distance => search_radius, :count => 100)
    end

    if nearby_instagram_content.count > 0
      for instagram in nearby_instagram_content
        if instagram.location.name != nil
          puts("#{instagram.location.name} (#{instagram.location.id})")
          #when working with proper names words like "the" and "a" hinder accuracy    
          instagram_location_name_clean = Venue.scrub_venue_name(instagram.location.name.downcase, city)
          venue_name_clean = Venue.scrub_venue_name(self.name.downcase, city)
        
          jarow_winkler_proximity = p jarow.getDistance(instagram_location_name_clean, venue_name_clean)

          if jarow_winkler_proximity >= 0.85 && ((self.name.downcase.include?("park") == true && instagram.location.name.downcase.include?("park")) == true || (self.name.downcase.include?("park") == false && instagram.location.name.downcase.include?("park") == false))
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
          puts ("Pinging Instagram for more Instagrams!")
          venue_instagrams = self.instagram_ping(true, false)
          self.update_columns(last_instagram_pull_time: Time.now + 10.minutes)
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

    if venue_instagrams != nil and venue_instagrams.first.nil? == false
      venue_instagrams.sort_by!{|instagram| -(instagram["created_time"].to_i)}
    else
      venue_instagrams = []
    end

    return venue_instagrams
  end

  def instagram_ping(day_pull = true, hourly_pull = false)
    #Returns a hash unless an hourly pull (open first open on version 1.1.0) then returns native Instgram object.

    #if no valid instagram location id we must set it.
    if (self.instagram_location_id == nil || self.instagram_location_id == 0) && (last_instagram_pull_time == nil or last_instagram_pull_time <= Time.now - 24.hours)
      self.set_instagram_location_id(100)
    end

    instagram_access_token_obj = InstagramAuthToken.where("is_valid IS TRUE").sample(1).first    
    if instagram_access_token_obj == nil
      client = Instagram.client
    else
      instagram_access_token = instagram_access_token_obj.token
      instagram_access_token_obj.increment!(:num_used, 1)
      client = Instagram.client(:access_token => instagram_access_token)
    end

    instagrams = []
    #If an explicity day pull (request all instagrams of that day until now) or the last Instagram pull was a day ago we make a pull of Instagram from the past 24 hours.
    if (day_pull == true && hourly_pull == false) || ((last_instagram_pull_time == nil or last_instagram_pull_time <= Time.now - 24.hours) || last_instagram_post == nil)
      instagrams = client.location_recent_media(self.instagram_location_id, :min_timestamp => (Time.now-24.hours).to_time.to_i).map(&:to_hash) rescue self.rescue_instagram_api_call(instagram_access_token, day_pull, false).map(&:to_hash)
      self.update_columns(last_instagram_pull_time: Time.now)
    #Else we only make a pull of instagrams from the past hour if explicity requested.
    elsif hourly_pull == true 
      instagrams = client.location_recent_media(self.instagram_location_id, :min_timestamp => (Time.now-1.hour).to_time.to_i) rescue self.rescue_instagram_api_call(instagram_access_token, false, true)
      self.update_columns(last_instagram_pull_time: Time.now)
    #Else make a hybrid call of Instagrams no older than a day but since the last Instagram that was pulled for the Venue.  
    else
      instagrams = client.location_recent_media(self.instagram_location_id, :min_id => self.last_instagram_id, :min_timestamp => (Time.now-24.hours).to_time.to_i).map(&:to_hash) rescue self.rescue_instagram_api_call(instagram_access_token, day_pull, false)
      #Instagram includes the post with the min_id specified...we need to filter it out.
      self.update_columns(last_instagram_pull_time: Time.now)
    end

    if instagrams.length > 0
      instagrams = instagrams.take instagrams.length-1
    else
      instagrams = []
    end

    if instagrams != nil and instagrams.first != nil
      return instagrams
    else
      puts "No Instagrams"
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
        Instagram.location_recent_media(self.instagram_location_id, :min_id => self.last_instagram_post, :min_timestamp => (Time.now-24.hours).to_time.to_i).map(&:to_hash) rescue []
      else
        if hourly_pull == true
          Instagram.location_recent_media(self.instagram_location_id, :min_timestamp => (Time.now-1.hour).to_time.to_i) rescue []
        else
          Instagram.location_recent_media(self.instagram_location_id, :min_timestamp => (Time.now-24.hours).to_time.to_i).map(&:to_hash) rescue []
        end
      end
    end
  end


  def self.surrounding_area_instagram_pull(lat, long)
    if lat != nil && long != nil
      
      surrounding_lyts_radius = 10000
      if not Venue.close_to(lat, long, surrounding_lyts_radius).where("color_rating > -1.0").any?
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
          #venue.set_last_venue_comment_details(instagrams.first)
          VenueComment.delay.map_instagrams_to_hashes_and_convert(instagrams)
        end
        #set venue's last vc fields to latest instagram
        #venue.set_last_venue_comment_details(vc)        
      end
    end
  end



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Twitter #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  def twitter_ping
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = '286I5Eu8LD64ApZyIZyftpXW2'
      config.consumer_secret     = '4bdQzIWp18JuHGcKJkTKSl4Oq440ETA636ox7f5oT0eqnSKxBv'
      config.access_token        = '2846465294-QPuUihpQp5FjOPlKAYanUBgRXhe3EWAUJMqLw0q'
      config.access_token_secret = 'mjYo0LoUnbKT4XYhyNfgH4n0xlr2GCoxBZzYyTPfuPGwk'
    end

    #determine radius for geo twitter pull. The less condfident we are in the prominence of the venue
    #the smaller we make the radius.
    if verified == true && (self.address == nil || self.address == "" || (self.address.downcase == self.name.downcase))
      radius =  1.0
    else
      radius = 0.075
    end

    #we construct the query which is composed of the venue name and the top trending tags (if present).
    query = ""
    top_tags = [self.trending_tags["tag_1"], self.trending_tags["tag_2"], self.trending_tags["tag_3"], self.trending_tags["tag_4"], self.trending_tags["tag_5"]].compact#self.meta_datas.order("relevance_score DESC LIMIT 5")
    if top_tags.count > 0
      top_tags.each{|tag| query+=(tag+" OR ")}        
      query+= self.name
    else
      query = self.name
    end

    if self.last_tweet_id  == nil
      min_tweet_id = LytitConstants.daily_tweet_id
    else
      min_tweet_id = [LytitConstants.daily_tweet_id, self.last_tweet_id].max
    end
    

    new_venue_tweets = client.search(query+" -rt", result_type: "recent", geocode: "#{latitude},#{longitude},#{radius}km", since_id: "#{min_tweet_id}").take(20).collect.to_a
    self.update_columns(last_twitter_pull_time: Time.now)

    if new_venue_tweets.length > 0
      new_venue_tweets.take new_venue_tweets.length-1
    else
      []
    end
  end

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Foursquare #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  def Venue.foursquare_venue_lookup(venue_name, venue_lat, venue_long, origin_city)
    client = Foursquare2::Client.new(:client_id => '35G1RAZOOSCK2MNDOMFQ0QALTP1URVG5ZQ30IXS2ZACFNWN1', :client_secret => 'ZVMBHYP04JOT2KM0A1T2HWLFDIEO1FM3M0UGTT532MHOWPD0', :api_version => '20120610')
    search_radius = 1000

    foursquare_search_results = client.search_venues(:ll => "#{venue_lat},#{venue_long}", :query => Venue.name_for_comparison(venue_name.downcase, origin_city), :radius => search_radius) rescue "F2 ERROR"
    if foursquare_search_results != "F2 ERROR" and (foursquare_search_results.first != nil and foursquare_search_results.first.last.count > 0)

      foursquare_venue = foursquare_search_results.first.last.first #first Foursquare Venue
      downcase_venue_name = venue_name.downcase
      if foursquare_venue != nil and (downcase_venue_name.include?(foursquare_venue.name.downcase) == false && (foursquare_venue.name.downcase).include?(downcase_venue_name) == false)
        #If foursquare_venue name is not equal or is not contained we do a string comparison
        require 'fuzzystringmatch'
        jarow = FuzzyStringMatch::JaroWinkler.create( :native )
        #overlap = venue_name.downcase.split & foursquare_venue.name.downcase.split
        #jarow_winkler_proximity = p jarow.getDistance(Venue.name_for_comparison(venue_name.downcase, origin_city).downcase, foursquare_venue.name.downcase.gsub("the" , "").gsub(origin_city, "").strip)#venue_name.downcase.gsub(overlap, "").trim, foursquare_venue.name.downcase.gsub(overlap, "").trim)
        jarow_winkler_proximity = p jarow.getDistance(downcase_venue_name, foursquare_venue.name.downcase)#venue_name.downcase.gsub(overlap, "").trim, foursquare_venue.name.downcase.gsub(overlap, "").trim)
        if jarow_winkler_proximity < 0.87
          foursquare_venue = nil
          for entry in foursquare_search_results.first.last
            #overlap = venue_name.downcase.split & entry.name.downcase.split
            #jarow_winkler_proximity = p jarow.getDistance(Venue.name_for_comparison(venue_name.downcase, origin_city).downcase, entry.name.downcase.gsub("the" , "").gsub(origin_city, "").strip)#(venue_name.downcase.gsub(overlap, "").trim, entry.name.downcase.gsub(overlap, "").trim)
            jarow_winkler_proximity = p jarow.getDistance(downcase_venue_name, entry.name.downcase)
            if jarow_winkler_proximity >= 0.87
              foursquare_venue = entry
              break
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

  def foursquare_venue
    client = Foursquare2::Client.new(:client_id => '35G1RAZOOSCK2MNDOMFQ0QALTP1URVG5ZQ30IXS2ZACFNWN1', :client_secret => 'ZVMBHYP04JOT2KM0A1T2HWLFDIEO1FM3M0UGTT532MHOWPD0', :api_version => '20120610')
    client.venue(self.foursquare_id)
  end







#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#DEPRECATED METHODS

#CLASS METHODS
  def Venue.discover(proximity, previous_venue_ids, user_lat, user_long)
    num_diverse_venues = 50
    nearby_radius = 5000.0 * 1/1000 #* 0.000621371 #meters to miles
    center_point = [user_lat, user_long]
    proximity_box = Geokit::Bounds.from_point_and_radius(center_point, nearby_radius, :units => :kms)

    previous_venue_ids = previous_venue_ids || "0"

    if proximity == "nearby"
      venue = Venue.in_bounds(proximity_box).where("id NOT IN (#{previous_venue_ids}) AND rating IS NOT NULL").order("popularity_rank DESC").limit(num_diverse_venues).shuffle.first
      if venue == nil
          if previous_venue_ids == "0"
            venue = Venue.where("(latitude <= #{proximity_box.sw.lat} OR latitude >= #{proximity_box.ne.lat}) OR (longitude <= #{proximity_box.sw.lng} OR longitude >= #{proximity_box.ne.lng}) AND rating IS NOT NULL").order("popularity_rank DESC").limit(num_diverse_venues).shuffle.first
          else
            venue = []
          end
      end
    else
      venue = Venue.where("(latitude <= #{proximity_box.sw.lat} OR latitude >= #{proximity_box.ne.lat}) OR (longitude <= #{proximity_box.sw.lng} OR longitude >= #{proximity_box.ne.lng}) AND rating IS NOT NULL").order("popularity_rank DESC").limit(num_diverse_venues).shuffle.first
    end

    return venue
  end

  def Venue.trending_venues(user_lat, user_long)
    total_trends = 10
    nearby_ratio = 0.7
    nearby_count = total_trends*nearby_ratio
    global_count = (total_trends-nearby_count)
    center_point = [user_lat, user_long]
    #proximity_box = Geokit::Bounds.from_point_and_radius(center_point, 5, :units => :kms)


    nearby_trends = Venue.close_to(center_point.first, center_point.last, 5000).where("rating IS NOT NULL").order("popularity_rank DESC").limit(nearby_count)
    if nearby_trends.count == 0
      global_trends = Venue.far_from(center_point.first, center_point.last, 50*1000).where("rating IS NOT NULL").order("popularity_rank DESC").limit(total_trends)
      return global_trends.shuffle
    else
      global_trends = Venue.far_from(center_point.first, center_point.last, 50*1000).where("rating IS NOT NULL").order("popularity_rank DESC").limit(global_count)
      return (nearby_trends+global_trends).shuffle
    end     
  end

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

#API METHODS

#Instagram
  def update_comments
    #Instagram is pulled only if venue is open
    if self.is_open?
      instagram_refresh_rate = 10 #minutes
      instagram_venue_id_ping_rate = 1 #days      

      if self.instagram_location_id != nil && self.last_instagram_pull_time != nil
        #try to establish instagram location id if previous attempts failed every 1 day
        if self.instagram_location_id == 0 
          if self.latest_posted_comment_time != nil and ((Time.now - instagram_venue_id_ping_rate.days >= self.latest_posted_comment_time) && (Time.now - (instagram_venue_id_ping_rate/2.0).days >= self.last_instagram_pull_time))
            new_instagrams = self.set_instagram_location_id(100)
            self.update_columns(last_instagram_pull_time: Time.now)
          else
            new_instagrams = []
          end
        elsif self.latest_posted_comment_time != nil and (Time.now - instagram_venue_id_ping_rate.days >= self.last_instagram_pull_time)
            new_instagrams = self.set_instagram_location_id(100)
            self.update_columns(last_instagram_pull_time: Time.now)
        else
          if ((Time.now - instagram_refresh_rate.minutes) >= self.last_instagram_pull_time)
            new_instagrams = self.instagram_ping(false, false)
          else
            new_instagrams = []
          end
        end
      else
        new_instagrams = self.set_instagram_location_id(150)
        self.update_columns(last_instagram_pull_time: Time.now)
      end
      #Delayed bulk conversion to venue comments
      if new_instagrams.count > 0
        VenueComment.delay.convert_bulk_instagrams_to_vcs(new_instagrams, self)
      end
      new_instagrams
    else
      []
    end
  end

  def get_instagrams(day_pull)
    last_instagram_id = nil

    instagrams = instagram_ping(day_pull, false)

    if instagrams.count > 0
      VenueComment.delay.convert_bulk_instagrams_to_vcs(instagrams, self)
    else
      instagrams = []
    end

    return instagrams
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

#Twitter
  def venue_twitter_tweets
    time_out_minutes = 5
    if self.last_twitter_pull_time == nil or (Time.now - self.last_twitter_pull_time > time_out_minutes.minutes)
      
      new_venue_tweets = self.update_tweets(true)

      total_venue_tweets = []
      if new_venue_tweets != nil
        #total_venue_tweets << new_venue_tweets.sort_by{|tweet| Tweet.popularity_score_calculation(tweet.user.followers_count, tweet.retweet_count, tweet.favorite_count)}
        total_venue_tweets << new_venue_tweets.sort_by{|tweet_1, tweet_2| Tweet.sort(tweet_1, tweet_2)}
      end
      total_venue_tweets << Tweet.where("venue_id = ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", id).order("timestamp DESC").order("popularity_score DESC")
      total_venue_tweets.flatten!.compact!
      return Kaminari.paginate_array(total_venue_tweets)
    else
      Tweet.where("venue_id = ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", id).order("timestamp DESC").order("popularity_score DESC")
    end
  end
  #total_venue_tweets << new_venue_tweets.sort_by{|tweet_1, tweet_2| Venue.tweet_sorting(tweet_1, tweet_2)}

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

      query = ""
      tags = MetaData.cluster_top_meta_tags(venue_ids).to_a      
      tags.each{|tag| query+=(tag.first.last+" OR ") if tag.first.last != nil || tag.first.last != ""}      
      query.chomp!(" OR ")

      tag_query_tweets = client.search(query+" -rt", result_type: "recent", geocode: "#{cluster_lat},#{cluster_long},#{radius}km").take(20).collect.to_a rescue nil      

      if tag_query_tweets != nil && tag_query_tweets.count > 0
        #tag_query_tweets.sort_by!{|tweet| Tweet.popularity_score_calculation(tweet.user.followers_count, tweet.retweet_count, tweet.favorite_count)}      
        tag_query_tweets.sort_by{|tweet_1, tweet_2| Tweet.sort(tweet_1, tweet_2)}
        Tweet.delay.bulk_conversion(tag_query_tweets, nil, cluster_lat, cluster_long, zoom_level, map_scale)
        tag_query_tweets << Tweet.in_bounds(search_box).where("associated_zoomlevel >= ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", zoom_level).order("timestamp DESC").order("popularity_score DESC")
        total_cluster_tweets = tag_query_tweets.flatten.compact
        return Kaminari.paginate_array(total_cluster_tweets)
      else
        total_cluster_tweets = Tweet.in_bounds(search_box).where("associated_zoomlevel >= ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", zoom_level).order("timestamp DESC").order("popularity_score DESC")
        return total_cluster_tweets
      end      
    else
      Tweet.in_bounds(search_box).where("associated_zoomlevel >= ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", zoom_level).order("timestamp DESC").order("popularity_score DESC")
    end
  end

  def update_tweets(delay_conversion)
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = '286I5Eu8LD64ApZyIZyftpXW2'
      config.consumer_secret     = '4bdQzIWp18JuHGcKJkTKSl4Oq440ETA636ox7f5oT0eqnSKxBv'
      config.access_token        = '2846465294-QPuUihpQp5FjOPlKAYanUBgRXhe3EWAUJMqLw0q'
      config.access_token_secret = 'mjYo0LoUnbKT4XYhyNfgH4n0xlr2GCoxBZzYyTPfuPGwk'
    end

    if verified == true && (self.address == nil || self.address == "" || (self.address.downcase == self.name.downcase))
      radius =  1.0
    else
      radius = 0.075 #Venue.meters_to_miles(100)
    end

    query = ""
    top_tags = [self.trending_tags["tag_1"], self.trending_tags["tag_2"], self.trending_tags["tag_3"], self.trending_tags["tag_4"], self.trending_tags["tag_5"]].compact#self.meta_datas.order("relevance_score DESC LIMIT 5")
    if top_tags.count > 0
      top_tags.each{|tag| query+=(tag+" OR ")}        
      query+= self.name
    else
      query = self.name
    end

    last_tweet_id = Tweet.where("venue_id = ?", self.id).order("twitter_id desc").first.try(:twitter_id)
      if last_tweet_id != nil
        new_venue_tweets = client.search(query+" -rt", result_type: "recent", geocode: "#{latitude},#{longitude},#{radius}km", since_id: "#{last_tweet_id}").take(20).collect.to_a rescue []
      else
        new_venue_tweets = client.search(query+" -rt", result_type: "recent", geocode: "#{latitude},#{longitude},#{radius}km").take(20).collect.to_a rescue []
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
  end

end
