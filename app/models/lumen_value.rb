class LumenValue < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue_comment
	belongs_to :lytit_vote

	after_create :new_lumens_notification


	def new_lumens_notification
		if ( (user.lumens - user.lumen_notification) >= 2.0 ) && user.version_compatible?("3.0.1")
			self.send_new_lumens_notification
			user.lumen_notification = user.lumens
			user.save
		end
	end


	def send_new_lumens_notification
		payload = {
		    :object_id => self.id, 
		    :type => 'new_lumens', 
		    :user_id => user.id
		}
		message = "+10 lumens received! You now have #{user.lumens.floor} lumens."
		notification = self.store_new_lumens_notification(payload, message)
		payload[:notification_id] = notification.id

		if user.push_token
		  count = Notification.where(user_id: user.id, read: false).count
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

	def store_new_lumens_notification(payload, message)
		notification = {
		  :payload => payload,
		  :gcm => user.gcm_token.present?,
		  :apns => user.push_token.present?,
		  :response => notification_payload,
		  :user_id => user.id,
		  :read => false,
		  :message => message,
		  :deleted => false
		}
		Notification.create(notification)
	end

	def notification_payload
	  {
	    :new_lumens => {
	      :addition => 10,
	      :lumens => user.lumens,
	    }
	    
	  }
	end

end
