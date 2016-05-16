class InstagramVortex < ActiveRecord::Base
	include PgSearch
	
	pg_search_scope :fuzzy_country_name_search, lambda{ |target_name, rigor|
	  raise ArgumentError unless rigor <= 1.0
	  {
	    :against => :country,
	    :query => target_name,
	    :using => {
	      :trigram => {
	        :threshold => rigor #higher value corresponds to stricter comparison
	      }
	    }
	  }
	}

	acts_as_mappable :default_units => :kms,
	             :default_formula => :sphere,
	             :distance_field_name => :distance,
	             :lat_column_name => :latitude,
	             :lng_column_name => :longitude
                     
	has_many :vortex_paths, :dependent => :destroy

	def InstagramVortex.global_pull
      vortexes = InstagramVortex.where("active IS TRUE")
      for vortex in vortexes
        puts "Entered vortex #{vortex.details}"
        vortex.pull
      end		
	end

	def InstagramVortex.city_pull(city)
		vortexes = InstagramVortex.where("active = ? AND city = ?", true, city)
		for vortex in vortexes
			vortex.pull
		end		
	end

	def pull
		self.update_columns(last_instagram_pull_time: Time.now)
		new_instagrams = Instagram.media_search(self.latitude, self.longitude, :distance => self.pull_radius, :count => 1000)
		new_instagrams.each do |instagram|
			VenueComment.create_vc_from_instagram(instagram.to_hash, nil, self, true)
		end
	end

	#circle-in
	def move
		#(109.0 * 1000) meters ~= 1 degree latitude
		path = self.vortex_paths.first
		if path != nil
			if self.movement_direction == nil
				#begin moving the vortex south 
				update_columns(movement_direction: 180)
				
				new_lat = latitude - path.increment_distance / (109.0 * 1000)
				update_columns(latitude: new_lat)
				update_columns(turn_cycle: 1)
			else
				#must check if we reached the center of the vortex_path. If so we move vortex back to the path origin. (the 1.3 is an over-rounded down sqrt(2))
				path_center_lat = path.origin_lat - (path.span/2) / (109.0 * 1000)
				path_center_long = path.origin_long + (path.span/2) / (113.2 * 1000 * Math.cos(path.origin_lat * Math::PI / 180))
				
				if Geocoder::Calculations.distance_between([latitude, longitude], [path_center_lat, path_center_long], :units => :km)*1000 < 1.3*path.increment_distance
					puts "Reached center, reseting..."
					puts "lat: #{latitude}, long: #{longitude}"
					update_columns(latitude: path.origin_lat)
					update_columns(longitude: path.origin_long)
					update_columns(turn_cycle: 1)
				else
					if self.movement_direction == 180
						new_lat = latitude - path.increment_distance*self.turn_cycle / (109.0 * 1000)
						if new_lat >= path.origin_lat - path.span / (109.0 * 1000)
							#keep moving vortex south
							puts "Moving south"
							puts "lat: #{latitude}, long: #{longitude}"
							update_columns(latitude: new_lat)
						else
							#move vortex east because reached path bound
							puts "Turned east"
							puts "lat: #{latitude}, long: #{longitude}"
							new_long = longitude + path.increment_distance / (113.2 * 1000 * Math.cos(latitude * Math::PI / 180))
							update_columns(longitude: new_long)
							update_columns(movement_direction: 90)
						end
					
					elsif self.movement_direction == 90
						new_long = longitude + path.increment_distance*self.turn_cycle / (113.2 * 1000 * Math.cos(latitude * Math::PI / 180))
						if new_long <= path.origin_long + path.span / (113.2 * 1000 * Math.cos(latitude * Math::PI / 180))
							#keep moving vortex east
							puts "Moving east"
							puts "lat: #{latitude}, long: #{longitude}"
							update_columns(longitude: new_long)
						else
							#move vortex north because reached path bound
							puts "Turn north"
							puts "lat: #{latitude}, long: #{longitude}"
							new_lat = latitude + path.increment_distance / (109.0 * 1000)
							update_columns(latitude: new_lat)
							update_columns(movement_direction: 0)
						end
					elsif self.movement_direction == 0
						new_lat = latitude + path.increment_distance*self.turn_cycle / (109.0 * 1000)
						if new_lat <= path.origin_lat
							#keep moving vortex north
							puts "Moving north"
							puts "lat: #{latitude}, long: #{longitude}"
							update_columns(latitude: new_lat)
						else
							#move vortex west because reached path bound
							puts "Turned west"
							puts "lat: #{latitude}, long: #{longitude}"
							new_long = longitude - path.increment_distance / (113.2 * 1000 * Math.cos(latitude * Math::PI / 180))
							update_columns(longitude: new_long)
							update_columns(movement_direction: 270)
						end
					else #180
						new_long = longitude - path.increment_distance*self.turn_cycle / (113.2 * 1000 * Math.cos(latitude * Math::PI / 180)) 
						if new_long >= path.origin_long
							#keep moving vortex west
							puts "Moving west"
							puts "lat: #{latitude}, long: #{longitude}"
							update_columns(longitude: new_long)
						else
							#move vortex south because reached path bound
							puts "Turned south"
							puts "lat: #{latitude}, long: #{longitude}"
							new_lat = latitude - path.increment_distance / (109.0 * 1000)
							update_columns(latitude: new_lat)
							update_columns(movement_direction: 180)
							self.increment!(:turn_cycle, 1)
						end
					
					end
				end
			end
		end

	end



	#circle-out
	def move_out
		#(109.0 * 1000) meters ~= 1 degree latitude
		path = self.vortex_paths.first
		if path != nil
			if self.movement_direction == nil
				#begin moving the vortex south 
				update_columns(movement_direction: 180)
				
				new_lat = latitude - path.increment_distance / (109.0 * 1000)
				update_columns(latitude: new_lat)
				update_columns(turn_cycle: 1)
			else
				#must check if we reached the center of the vortex_path. If so we move vortex back to the path origin. (the 1.3 is an over-rounded down sqrt(2))
				path_center_lat = path.origin_lat - (path.span/2) / (109.0 * 1000)
				path_center_long = path.origin_long + (path.span/2) / (113.2 * 1000 * Math.cos(path.origin_lat * Math::PI / 180))
				
				if Geocoder::Calculations.distance_between([latitude, longitude], [path_center_lat, path_center_long], :units => :km)*1000 < 1.3*path.increment_distance
					puts "Reached center, reseting..."
					puts "lat: #{latitude}, long: #{longitude}"
					update_columns(latitude: path.origin_lat)
					update_columns(longitude: path.origin_long)
					update_columns(turn_cycle: 1)
				else
					if self.movement_direction == 180
						new_lat = latitude - path.increment_distance*self.turn_cycle / (109.0 * 1000)
						if new_lat >= path.origin_lat - path.span / (109.0 * 1000)
							#keep moving vortex south
							puts "Moving south"
							puts "lat: #{latitude}, long: #{longitude}"
							update_columns(latitude: new_lat)
						else
							#move vortex east because reached path bound
							puts "Turned east"
							puts "lat: #{latitude}, long: #{longitude}"
							new_long = longitude + path.increment_distance / (113.2 * 1000 * Math.cos(latitude * Math::PI / 180))
							update_columns(longitude: new_long)
							update_columns(movement_direction: 90)
						end
					
					elsif self.movement_direction == 90
						new_long = longitude + path.increment_distance*self.turn_cycle / (113.2 * 1000 * Math.cos(latitude * Math::PI / 180))
						if new_long <= path.origin_long + path.span / (113.2 * 1000 * Math.cos(latitude * Math::PI / 180))
							#keep moving vortex east
							puts "Moving east"
							puts "lat: #{latitude}, long: #{longitude}"
							update_columns(longitude: new_long)
						else
							#move vortex north because reached path bound
							puts "Turn north"
							puts "lat: #{latitude}, long: #{longitude}"
							new_lat = latitude + path.increment_distance / (109.0 * 1000)
							update_columns(latitude: new_lat)
							update_columns(movement_direction: 0)
						end
					elsif self.movement_direction == 0
						new_lat = latitude + path.increment_distance*self.turn_cycle / (109.0 * 1000)
						if new_lat <= path.origin_lat
							#keep moving vortex north
							puts "Moving north"
							puts "lat: #{latitude}, long: #{longitude}"
							update_columns(latitude: new_lat)
						else
							#move vortex west because reached path bound
							puts "Turned west"
							puts "lat: #{latitude}, long: #{longitude}"
							new_long = longitude - path.increment_distance / (113.2 * 1000 * Math.cos(latitude * Math::PI / 180))
							update_columns(longitude: new_long)
							update_columns(movement_direction: 270)
						end
					else #180
						new_long = longitude - path.increment_distance*self.turn_cycle / (113.2 * 1000 * Math.cos(latitude * Math::PI / 180)) 
						if new_long >= path.origin_long
							#keep moving vortex west
							puts "Moving west"
							puts "lat: #{latitude}, long: #{longitude}"
							update_columns(longitude: new_long)
						else
							#move vortex south because reached path bound
							puts "Turned south"
							puts "lat: #{latitude}, long: #{longitude}"
							new_lat = latitude - path.increment_distance / (109.0 * 1000)
							update_columns(latitude: new_lat)
							update_columns(movement_direction: 180)
							self.increment!(:turn_cycle, 1)
						end
					
					end
				end
			end
		end

	end	

	def self.check_nearby_vortex_existence(lat, long)
		if lat != nil and long != nil
			search_box = Geokit::Bounds.from_point_and_radius([lat,long], 20, :units => :kms)
			nearby_vortex = InstagramVortex.in_bounds(search_box).order("id ASC").first
			#nearby_vortex = InstagramVortex.within(nearby_vortex_radius.to_i, :units => :kms, :origin => [lat, long]).first
			if nearby_vortex == nil
				begin
					user_city = Venue.reverse_geo_city_lookup(lat, long)
					user_country = Venue.reverse_geo_country_lookup(lat, long)
					if user_city != nil
						iv = InstagramVortex.create!(:latitude => lat, :longitude => long, :pull_radius => 5000, :active => true, :city => user_city, :country => user_country, :details => "auto generated")
						iv.set_timezone_offsets
					end
					#vp = VortexPath.create!(:origin_lat => lat, :origin_long => long, :span => 15000, :increment_distance => 5000, :instagram_vortex_id => iv.id)
				rescue
					puts "Oops! Something went wrong in creating a vortex."
				end
			else
				if nearby_vortex.active == false
					nearby_vortex.update_columns(active: true)
					nearby_vortex.update_columns(last_user_ping: Time.now)
				else
					nearby_vortex.update_columns(last_user_ping: Time.now)
				end
			end
		end

	end

	def set_timezone_offsets
      Timezone::Configure.begin do |c|
      c.username = 'LYTiT'
      end
      timezone = Timezone::Zone.new :latlon => [self.latitude, self.longitude] rescue nil

      self.time_zone = timezone.active_support_time_zone rescue nil
      self.time_zone_offset = Time.now.in_time_zone(timezone.active_support_time_zone).utc_offset/3600.0 rescue nil
      self.save
	end

	def InstagramVortex.stale_vortex_check
	    vortexes = InstagramVortex.all
	    for vortex in vortexes
	        if vortex.details == "auto generated" && (vortex.last_user_ping == nil or vortex.last_user_ping < (Time.now-2.days))
	            if vortex.created_at < Time.now - 5.days
	                vortex.delete
	            else
	                vortex.update_columns(active: false)
	            end
	        end
	    end
	end

end