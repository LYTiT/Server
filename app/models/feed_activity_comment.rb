class ActivityComment < ActiveRecord::Base
	belongs_to :user
	belongs_to :activity

	after_create :new_chat_notification

	def new_chat_notification
		conversation_participant_ids = "SELECT user_id FROM activity_comments WHERE activity_id = #{self.activity_id}"
		feed_users = FeedUser.where("(user_id IN (#{conversation_participant_ids}) OR user_id = ?) AND feed_id = ?", activity.user_id, self.activity.feed_id)

		for feed_user in feed_users
			if feed_user.is_subscribed == true && (feed_user.user_id != self.user_id && feed_user.user_id != nil)
				self.send_new_chat_notification(feed_user.user)
			end
		end
	end

	def send_new_chat_notification(member)
		payload = {
		    :object_id => self.id, 
		    :activity_id => activity_id,
		    :activity_type => activity.activity_type,
		    :media_type => activity.feed_share.try(:media_type),
		    :activity_user_name => activity.user.try(:name),
		    :activity_user_id => activity.user_id,
		    :activity_user_phone => activity.user.try(:phone_number),
		    :type => 'chat_notification', 
		    :user_id => user.id,
		    :user_name => user.name,
		    :user_phone => user.phone_number,
		    :feed_id => activity.feed_id,
		    :feed_name => activity.feed.name,
		    :feed_color => activity.feed.feed_color,
		    :chat_message => self.comment,

		}

		notification_type = "New comment for Feed Activity #{activity_id}"
		#if Notification.where(user_id: member.id, message: notification_type, read: false, deleted: false).count == 0
		notification = self.store_new_chat_notification(payload, member, notification_type)
		payload[:notification_id] = notification.id
		#end

		preview = "#{user.name} in"+' "'+"#{activity.feed.name}"+'"'+":\n#{comment}"
		if member.push_token
		  count = Notification.where(user_id: member.id, read: false, deleted: false).count
		  APNS.send_notification(member.push_token, { :priority =>10, :alert => preview, :content_available => 1, :other => payload, :badge => count})
		end
	end

	def store_new_chat_notification(payload, member, type)
		notification = {
		  :payload => payload,
		  :gcm => user.gcm_token.present?,
		  :apns => user.push_token.present?,
		  :response => notification_payload,
		  :user_id => member.id,
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