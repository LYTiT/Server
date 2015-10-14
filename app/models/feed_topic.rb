class FeedTopic < ActiveRecord::Base
	belongs_to :feed
	belongs_to :user
	has_one :feed_activity, :dependent => :destroy

	after_create :create_feed_acitivity
	after_create :new_topic_notification

	def create_feed_acitivity
		FeedActivity.create!(:feed_topic_id => id, :feed_id => feed_id, :user_id => user_id, :activity_type => "new topic", :adjusted_sort_position => Time.now.to_i)
	end

	def new_topic_notification
		feed_users = FeedUser.where("feed_id = ?", feed_id)
		for feed_user in feed_users
			if feed_user.is_subscribed == true && (feed_user.user_id != self.user_id && feed_user.user != nil)
				self.delay.send_new_topic_notification(feed_user.user)
			end
		end
	end

	def send_new_topic_notification(member)
		payload = {
		    :object_id => self.id, 
		    :activity_id => feed_activity.id,
		    :type => 'new_topic_notification', 
		    :user_id => user_id,
		    :user_name => user.name,
		    :user_phone => user.phone_number,
		    :feed_id => feed_id,
		    :feed_name => feed.name,
		    :topic => self.message
		}


		type = "New feed topic opened"

		notification = self.store_new_topic_notification(payload, member, type)
		payload[:notification_id] = notification.id

		preview = "#{user.name} opened a new topic in #{feed_activity.feed.name}"
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