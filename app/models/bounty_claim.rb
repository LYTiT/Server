class BountyClaim < ActiveRecord::Base
	belongs_to :user
	belongs_to :bounty

	belongs_to :venue_comment

	validate :proper_media_type

	def proper_media_type
		if self.venue_comment.media_type != self.bounty.media_type
			errors.add('Improper bounty claim media type. Please try again.')
		end
	end

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