class MomentRequest < ActiveRecord::Base
	acts_as_mappable :default_units => :kms,
	             :default_formula => :sphere,
	             :distance_field_name => :distance,
	             :lat_column_name => :latitude,
	             :lng_column_name => :longitude

	belongs_to :user
	belongs_to :venue
	has_many :moment_request_users, :dependent => :destroy 

	def MomentRequest.get_surrounding_request(lat, long, u_id)
		search_box = Geokit::Bounds.from_point_and_radius([lat, long], 0.2, :units => :kms)
		MomentRequest.in_bounds(search_box).where("expiration <= ? AND user_id != ?", Time.now, u_id).includes(:venue)
	end

end