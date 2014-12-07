class Relationship < ActiveRecord::Base
	belongs_to :follower, class_name: "User"
	belongs_to :followed, class_name: "User"
	validates :follower_id, presence: true
	validates :followed_id, presence: true

	after_create :new_follower_notification


	def new_follower_notification
		self.send_new_follower_notification
	end


	def send_new_follower_notification
		payload = {
		    :object_id => self.id, 
		    :type => 'new_follower', 
		    :user_id => followed_id
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
		new_follower = follower.as_json()
		notification = {
		  :payload => payload,
		  :gcm => user.gcm_token.present?,
		  :apns => user.push_token.present?,
		  :response => new_follower,
		  :user_id => user.id,
		  :read => false,
		  :message => message,
		  :deleted => false
		}
		Notification.create(notification)
	end

end
