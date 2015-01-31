class BountyClaim < ActiveRecord::Base
	belongs_to :user
	belongs_to :bounty

	has_many :venue_comments

	def accepted
		reward = bounty.lumen_reward
		user.lumens = user.lumens + reward
		user.save

		venue = bounty.venue
		venue.outstanding_bounties = venue.outstanding_bounties - 1 
		venue.save

		bounty.valid = false
		bounty.save
		#SEND NOTIFICATION TO RESPONDER
	end

	def rejected
		#SEND NOTIFICATION TO RESPONDER
	end

end