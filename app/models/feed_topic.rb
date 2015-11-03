class FeedTopic < ActiveRecord::Base
	belongs_to :feed
	belongs_to :user
	has_one :activity, :dependent => :destroy

	after_create :create_feed_acitivity
	after_create :new_topic_notification

	def self.implicit_creation(u_id, topic_message, target_feed_ids)
		ft = FeedTopic.create!(:user_id => u_id, :feed_id => target_feed_id, :message => topic_message)
		for target_feed_id in target_feed_ids
			TopicLinkedFeeds.create!(:feed_topic_id => self.id, :feed_id => target_feed_id)
		end
	end

	def create_feed_acitivity
		Activity.implicit_topic_activity_create(self.id, self.user_id, self.feed_id, self.message)
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
		    :activity_id => activity.id,
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

		preview = "#{user.name} opened a new topic in #{activity.feed.name}"
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