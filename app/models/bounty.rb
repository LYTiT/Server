class Bounty < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue

	has_many :bounty_claims, :dependent => :destroy
	has_many :venue_comments, through: :bounty_claims, source: :venue_comment

	def check_validity
		result = true
		if self.expiration.to_time < Time.now
			venue.outstanding_bounties = venue.outstanding_bounties - 1
			venue.save

			wrap_around_claim_time = self.last_viewed_claim_time || Time.now - 121.minutes

			if bounty_claims.count == 0 || wrap_around_claim_time < (Time.now - 120.minutes) #cleanup
				self.validity = false
				result = false
				self.save
			end
		end
		return result
	end

	def viewed_claim
		self.last_viewed_claim_time = Time.now
		save
	end
end