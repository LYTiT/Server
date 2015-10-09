class FeedActivityComment < ActiveRecord::Base
	belongs_to :user
	belongs_to :feed_activity

	after_create :new_comment_notification

	def new_comment_notification
		feed_members = feed_activity.feed.feed_users

		for feed_user in feed_members
			if feed_user.is_subscribed == true && (feed_user.user_id != self.user_id)
				#might have to do a delay here/run on a seperate dyno
				begin
					self.delay.send_new_message_notification(feed_user.user)
				rescue
					puts "Nil User encountered!"
				end
			end
		end
	end

	def send_new_message_notification(member)
		payload = {
		    :object_id => self.id, 
		    :feed_activity_id => feed_activity_id,
		    :type => 'activity_comment_notification', 
		    :user_id => user.id,
		    :user_name => user.name,
		    :user_phone => user.phone_number,
		    :feed_id => feed.id,
		    :feed_name => feed.name,
		    :comment => self.comment,

		}

		notification_type = "New Feed Activity Comment"
		notification = self.store_new_message_notification(payload, member, notification_type)
		payload[:notification_id] = notification.id

		if member.push_token
		  count = Notification.where(user_id: member.id, read: false, deleted: false).count
		  APNS.send_notification(member.push_token, { :priority =>10, :alert => message, :content_available => 1, :other => payload, :badge => count})
		end

	end

	def store_new_message_notification(payload, member, type)
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