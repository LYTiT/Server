class FeedMessage < ActiveRecord::Base
	belongs_to :user
	belongs_to :feed

	after_create :new_message_notification

	def new_message_notification
		feed_members = feed.feed_users

		for feed_user in feed.users
			if feed_user.is_subscribed == true
				#might have to do a delay here/run on a seperate dyno
				self.send_new_message_notification(feed_user)
			end
		end
	end


	def send_new_message_notification(feed_user)
		payload = {
		    :object_id => self.id, 
		    :type => 'chat_notification', 
		    :user_id => user.id,
		    :user_name => user.name,
		    :user_phone => user.phone,
		    :feed_id => feed.id,
		    :feed_name => feed.name,
		    :chat_message => self.message

		}

		#A feed should have only 1 new chat message notification contribution to the badge count thus we create a chat notification only once,
		#when there is an unread message
		if Notification.where(message: "There are new messages in your #{self.feed.name} List", read: false, deleted: false).count == 0
			message = "There are new messages in your #{self.feed.name} List"
			notification = self.store_new_message_notification(payload, feed_user, message)
			payload[:notification_id] = notification.id
		end

		if feed_user.push_token
		  count = Notification.where(user_id: feed_user.id, read: false, deleted: false).count
		  APNS.delay.send_notification(feed_user.push_token, { :priority =>10, :alert => message, :content_available => 1, :other => payload, :badge => count})
		end

	end

	def store_new_message_notification(payload, feed_user, message)
		notification = {
		  :payload => payload,
		  :gcm => user.gcm_token.present?,
		  :apns => user.push_token.present?,
		  :response => notification_payload,
		  :user_id => feed_user.id,
		  :read => false,
		  :message => message,
		  :deleted => false
		}
		Notification.create(notification)
	end

	def notification_payload
	  	nil
	end


end