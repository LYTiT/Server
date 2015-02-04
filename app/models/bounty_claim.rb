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
		notification = self.store_new_bounty_claim_notification(payload, bounty.user, message)
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

	#If a Bounty Claim is accepted lumens are transfered and notification to the responder is sent
	def acceptance
		reward = bounty.lumen_reward
		bounty_lumen_value = LumenValue.new(:value => reward*(0.9), :user_id => user.id, :bounty_id => bounty.id)
		user.lumens = user.lumens + reward*(0.9) #10% is given back to the bounty issuer as a sign of good faith
		bounty_lumen_value.save
		user.save

		bounty_issuer = self.bounty.user
		bounty_issuer.lumens = bounty_issuer.lumens + reward*(0.1)
		bounty_issuer.save

		venue = bounty.venue
		venue.outstanding_bounties = venue.outstanding_bounties - 1 
		venue.save

		bounty.validity = false
		bounty.save
		self.bounty_claim_accept_notification
	end

	def bounty_claim_accept_notification
		self.delay.send_bounty_claim_accept_notification
	end

	def send_bounty_claim_accept_notification
		payload = {
		    :object_id => bounty.id,
		    :type => 'bounty_claim_acceptance', 
		    :user_id => user_id
		}
		message = "Congratulations! Your Bounty Claim at #{bounty.venue.name} has been accepted"
		notification = self.store_new_bounty_claim_accept_notification(payload, user, message)
		payload[:notification_id] = notification.id

		if bounty.user.push_token
		  count = Notification.where(user_id: user_id, read: false).count
		  APNS.delay.send_notification(user.push_token, { :priority =>10, :alert => message, :content_available => 1, :other => payload, :badge => count})
		end

		if user.gcm_token
		  gcm_payload = payload.dup
		  gcm_payload[:message] = message
		  options = {
		    :data => gcm_payload
		  }
		  request = HiGCM::Sender.new(ENV['GCM_API_KEY'])
		  request.send([user.gcm_token], options)
		end
	end

	def store_new_bounty_claim_accept_notification(payload, user, message)
		notification = {
		  :payload => payload,
		  :gcm => user.gcm_token.present?,
		  :apns => user.push_token.present?,
		  :response => acceptance_notification_payload,
		  :user_id => user.id,
		  :read => false,
		  :message => message,
		  :deleted => false
		}
		Notification.create(notification)
	end

	def acceptance_notification_payload
	  {
    	:bounty => {
			:id => self.bounty.id,
			:lumens => (self.bounty.lumen_reward)*0.9,
			:venue => self.bounty.venue.name
		}
	  }
	end

	#If a Bounty Claim is rejected a notification to the responder with the reason for rejection is sent
	def rejection(reason)
		self.rejected = true
		self.rejection_reason = reasoning
		self.bounty_response_rejection_notification(reason)
		save
	end

	def bount_response_rejection_notification
		self.delay.send_bounty_response_reject_notification
	end

	def send_bounty_claim_accept_notification
		payload = {
		    :object_id => self.id,
		    :type => 'bounty_claim_rejection', 
		    :user_id => user_id
		}
		message = "Your Bounty Claim at #{bounty.venue.name} has been rejected"
		notification = self.store_new_bounty_claim_reject_notification(payload, user, message)
		payload[:notification_id] = notification.id

		if bounty.user.push_token
		  count = Notification.where(user_id: user_id, read: false).count
		  APNS.delay.send_notification(user.push_token, { :priority =>10, :alert => message, :content_available => 1, :other => payload, :badge => count})
		end

		if user.gcm_token
		  gcm_payload = payload.dup
		  gcm_payload[:message] = message
		  options = {
		    :data => gcm_payload
		  }
		  request = HiGCM::Sender.new(ENV['GCM_API_KEY'])
		  request.send([user.gcm_token], options)
		end
	end

	def store_new_bounty_claim_reject_notification(payload, user, message)
		notification = {
		  :payload => payload,
		  :gcm => user.gcm_token.present?,
		  :apns => user.push_token.present?,
		  :response => acceptance_notification_payload,
		  :user_id => user.id,
		  :read => false,
		  :message => message,
		  :deleted => false
		}
		Notification.create(notification)
	end

	def acceptance_notification_payload
	  {
    	:bounty => {
			:id => self.bounty.id,
			:reason => self.rejection_reason
		}
	  }
	end

end