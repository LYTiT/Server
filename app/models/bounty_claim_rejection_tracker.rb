class BountyClaimRejectionTracker < ActiveRecord::Base
	belongs_to :user
	belongs_to :bounty_claim
end