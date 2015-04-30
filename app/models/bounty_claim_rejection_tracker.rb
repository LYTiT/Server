class BountyClaimRejectionTracker < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue_comment
end