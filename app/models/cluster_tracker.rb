class ClusterTracker < ActiveRecord::Base

	def self.check_existence(lat, long, zoom)
		result = ClusterTracker.where("latitude = ? AND longitude = ? AND zoom_level = ?", lat, long, zoom).first
		if result == nil
			ClusterTracker.create!(:latitude => lat, :longitude => long, :zoom_level => zoom)
		else
			result
		end
	end
end