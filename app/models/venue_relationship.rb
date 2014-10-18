class VenueRelationship < ActiveRecord::Base
	belongs_to :ufollower, class_name: "User"
	belongs_to :vfollowed, class_name: "Venue"
	validates :ufollower_id, presence: true
	validates :vfollowed_id, presence: true
end
