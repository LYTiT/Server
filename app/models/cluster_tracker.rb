class ClusterTracker < ActiveRecord::Base

	def self.check_existence(lat, long, zoom)
		result = ClusterTracker.where("latitude = ? AND longitude = ? AND zoom_level = ?", lat, long, zoom).first
		if result == nil
			new_cluster_tracker = ClusterTracker.create!(:latitude => lat, :longitude => long, :zoom_level => zoom)
		else
			return result
		end
	end
end