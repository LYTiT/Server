class FeedUser < ActiveRecord::Base
	belongs_to :user
	belongs_to :feed

	after_create :new_message_notification

	def new_message_notification
		if FeedUser.where("feed_id = ? AND user_id =?", feed.id, feed.user.id).first.is_subscribed == true
			self.send_new_message_notification
		end
	end

	def send_new_message_notification
		payload = {
		    :object_id => self.id, 
		    :type => 'added_list_notification', 
		    :user_id => user.id,
		    :user_name => user.name,
		    :feed_id => feed.id,
		    :feed_name => feed.name

		}

		#A feed should have only 1 new chat message notification contribution to the badge count thus we create a chat notification only once,
		#when there is an unread message
		type = "#{user.name} added your #{feed.name} List"

		notification = self.store_new_message_notification(payload, feed.user, type)
		payload[:notification_id] = notification.id

		if feed.user.push_token
		  count = Notification.where(user_id: feed.user.id, read: false, deleted: false).count
		  APNS.send_notification(feed.user.push_token, { :priority =>10, :alert => type, :content_available => 1, :other => payload, :badge => count})
		end

	end

	def store_new_message_notification(payload, user, type)
		notification = {
		  :payload => payload,
		  :gcm => feed.user.gcm_token.present?,
		  :apns => feed.user.push_token.present?,
		  :response => notification_payload,
		  :user_id => feed.user.id,
		  :read => false,
		  :message => type,
		  :deleted => false
		}
		Notification.create(notification)
	end

	def notification_payload
	  	nil
	end


end
