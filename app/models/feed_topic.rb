class FeedTopic < ActiveRecord::Base
	belongs_to :user
	has_many :feed_activities, :dependent => :destroy

	after_create :new_topic_notification

	def new_topic_notification
		feed_users = FeedUser.where("feed_id = ?", feed_activities.first.feed.id)
		for feed_user in feed_users
			if feed_user.is_subscribed == true && (feed_user.user_id != self.user_id && feed_user.user_id != nil)
				self.delay.send_new_topic_notification(feed_user.user)
			end
		end
	end

	def send_new_topic_notification(member)
		payload = {
		    :object_id => self.id, 
		    :feed_activity_id => feed_activities.first.id,
		    :type => 'new_topic_notification', 
		    :user_id => user_id,
		    :user_name => user.name,
		    :user_phone => user.phone_number,
		    :feed_id => feed_activities.first.feed.id,
		    :feed_name => feed_activities.first.feed.name,
		    :topic => self.message
		}


		type = "New feed topic opened"

		notification = self.store_new_topic_notification(payload, member, type)
		payload[:notification_id] = notification.id

		preview = "#{user.name} opened a new topic in #{feed_activities.first.feed.name}"
		if member.push_token
		  count = Notification.where(user_id: member.id, read: false, deleted: false).count
		  APNS.send_notification(member.push_token, { :priority =>10, :alert => preview, :content_available => 1, :other => payload, :badge => count})
		end

	end

	def store_new_topic_notification(payload, member, type)
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