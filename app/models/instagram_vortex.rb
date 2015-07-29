class InstagramVortex < ActiveRecord::Base
	has_many :vortex_paths, :dependent => :destroy

	def move
		#(109.0 * 1000) meters ~= 1 degree latitude
		path = self.vortex_paths.first
		if path != nil
			if self.movement_direction == nil
				#begin moving the vortex south 
				update_columns(movement_direction: 270)
				
				new_lat = latitude - path.increment_distance / (109.0 * 1000)
				update_columns(latitude: new_lat)
				update_columns(turn_cycle: 1)
			else
				#must check if we reached the center of the vortex_path. If so we move vortex back to the path origin. (the 1.3 is an over-rounded down sqrt(2))
				path_center_lat = path.origin_lat - (path.span/2) / (109.0 * 1000)
				path_center_long = path.origin_long + (path.span/2) / (113.2 * 1000 * Math.cos(path.origin_lat * Math::PI / 180))
				
				if Geocoder::Calculations.distance_between([latitude, longitude], [path_center_lat, path_center_long])*1609.34 < 1.3*path.increment_distance
					puts "Reached center, reseting..."
					puts "lat: #{latitude}, long: #{longitude}"
					update_columns(latitude: path.origin_lat)
					update_columns(longitude: path.origin_long)
					update_columns(turn_cycle: 1)
				else
					if self.movement_direction == 270
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
							update_columns(movement_direction: 360)
						end
					
					elsif self.movement_direction == 360
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
							update_columns(movement_direction: 90)
						end
					elsif self.movement_direction == 90
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
							update_columns(movement_direction: 180)
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
							update_columns(movement_direction: 270)
							self.increment!(:turn_cycle, 1)
						end
					
					end
				end
			end
		end

	end

end