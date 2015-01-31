class Bounty < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue

	has_many :bounty_claims, :dependent => :destroy
	has_many :venue_comments, through: :bounty_claims, source: :venue_comment

	def is_valid?
		if self.expiration.to_time < Time.now
			self.validity = false
			venue.outstanding_bounties = venue.outstanding_bounties - 1
			venue.save
			save
			return false
		else
			return true
		end
	end

end