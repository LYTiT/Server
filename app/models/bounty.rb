class Bounty < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue

	has_many :venue_comments

	def check_validity
		result = true

		if self.expiration.to_time < Time.now && self.validity == true
			venue.outstanding_bounties = venue.outstanding_bounties - 1
			venue.save

			wrap_around_claim_time = self.last_viewed_claim_time || Time.now - 121.minutes #a Bounty is still valid 2 hours after the last response to it is viewed even if it expires

			if bounty_claims.count == 0 || wrap_around_claim_time < (Time.now - 120.minutes) #cleanup
				self.validity = false
				result = false
				self.save
			end

			if bounty_claims.count == 0 && self.lumen_reward > 0.0#if no responses received we return the deposited lumens for the request back to the user
				user_lumens = user.lumens 
				user.update_columns(lumens: user_lumens+self.lumen_reward)
				self.update_columns(lumen_reward: 0.0)
			end

		end
		return result
	end

	def viewed_claim
		self.last_viewed_claim_time = Time.now
		self.response_received = false
		save
	end

	def new_claims
		if self.last_viewed_claim_time == nil
			return self.venue_comments.where("user_id IS NOT NULL").count
		else
			return self.venue_comments.where("user_id IS NOT NULL AND created_at > ?", self.last_viewed_claim_time).count
		end
	end

	def minutes_left
		(self.expiration - Time.now)
	end

	def total_valid_claims
		claims_count = self.venue_comments.where("user_id IS NOT NULL AND is_claim_accepted != false").count
	end


end