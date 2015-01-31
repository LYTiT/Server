class BountyClaim < ActiveRecord::Base
	belongs_to :user
	belongs_to :bounty

	belongs_to :venue_comment

	validate :proper_media_type

	after_create :bounty_claim_notification

	def proper_media_type
		if self.venue_comment.media_type != self.bounty.media_type
			errors.add(:media_type, 'does not match Bounty request. Please try again')
		end
	end

	def bounty_claim_notification
		self.delay.send_bounty_claim_notification
	end

	def send_bounty_claim_notification
		payload = {
		    :object_id => self.id, 
		    :type => 'bounty_claim', 
		    :user_id => bounty.user_id
		}
		message = "Someone responded to your Bounty at #{bounty.venue.name}"
		notification = self.store_new_bounty_claim_notification((payload, bounty.user, message)
		payload[:notification_id] = notification.id

		if bounty.user.push_token
		  count = Notification.where(user_id: bounty.user_id, read: false).count
		  APNS.delay.send_notification(bounty.user.push_token, { :priority =>10, :alert => message, :content_available => 1, :other => payload, :badge => count})
		end

		if bounty.user.gcm_token
		  gcm_payload = payload.dup
		  gcm_payload[:message] = message
		  options = {
		    :data => gcm_payload
		  }
		  request = HiGCM::Sender.new(ENV['GCM_API_KEY'])
		  request.send([bounty.user.gcm_token], options)
		end
		
	end

	def store_new_bounty_claim_notification(payload, payer, message)
		notification = {
		  :payload => payload,
		  :gcm => payer.gcm_token.present?,
		  :apns => payer.push_token.present?,
		  :response => notification_payload,
		  :user_id => payer.id,
		  :read => false,
		  :message => message,
		  :deleted => false
		}
		Notification.create(notification)
	end

	def notification_payload
	  {
    	:bounty => {
			:id => self.bounty.id,
		}
	  }
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