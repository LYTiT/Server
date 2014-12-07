class LumenValue < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue_comment
	belongs_to :lytit_vote

	#after_create :lumens_received_notification

=begin
	def lumens_received_notification
		if user.weekly_lumens.last 
			self.send_lumens_received_notification
		end
	end


	def send_lumens_received_notification
		payload = {
		    :object_id => self.id, 
		    :type => 'lumens_received', 
		    :user_id => user.id
		}
		message = "#{follower.name} is now following you"
		notification = self.store_new_follower_notification(payload, followed, message)
		payload[:notification_id] = notification.id

		if followed.push_token
		  count = Notification.where(user_id: followed_id, read: false).count
		  APNS.delay.send_notification(followed.push_token, { :priority =>10, :alert => message, :content_available => 1, :other => payload, :badge => count})
		end

		if followed.gcm_token
		  gcm_payload = payload.dup
		  gcm_payload[:message] = message
		  options = {
		    :data => gcm_payload
		  }
		  request = HiGCM::Sender.new(ENV['GCM_API_KEY'])
		  request.send([followed.gcm_token], options)
		end

	end

	def store_new_follower_notification(payload, user, message)
		notification = {
		  :payload => payload,
		  :gcm => user.gcm_token.present?,
		  :apns => user.push_token.present?,
		  #:response => notification_payload(user),
		  :user_id => user.id,
		  :read => false,
		  :message => message,
		  :deleted => false
		}
		Notification.create(notification)
	end
=end

end
