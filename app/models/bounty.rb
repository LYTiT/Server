class Bounty < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue

	has_many :bounty_claims, :dependent => :destroy
	has_many :venue_comments, through: :bounty_claims, source: :venue_comment

	def check_validity
		if self.expiration.to_time < Time.now
			venue.outstanding_bounties = venue.outstanding_bounties - 1
			venue.save

			if bounty_claims.count == 0 || self.last_viewed_claim_time < (Time.now - 120.minutes) #cleanup
				self.validity = false
			end

			save
		end
	end

	def viewed_claim
		self.last_viewed_claim_time = Time.now
		save
	end
end