class Like < ActiveRecord::Base
	belongs_to :liker, class_name: "User" 
	belongs_to :liked, class_name: "User"
	
	belongs_to :feed_venue

	belongs_to :feed_activity

	validates :liker_id, presence: true
	validates :liked_id, presence: true

	after_create :new_like_notification

	def new_like_notification
		if feed_activity.user_id != liker_id
			self.delay.send_new_like_notification
		end
	end

	def send_new_like_notification
		if feed_activity.activity_type == "added venue"
			payload_type = "added_venue_like_notification"
			message = "#{liker.name} has liked your added venue to #{feed_activity.feed.name}"
			notification_type = "Added venue like"
		else
			payload_type = "share_like_notification"
			message = "#{liker.name} has liked your shared Moment in #{feed_activity.feed.name}"
			notification_type = "Message like"
		end

		payload = {
		    :object_id => self.id, 
		    :type => "like_notification",
		    :activity_id => feed_activity.id,
		    :activity_type => feed_activity.activity_type,
		    :user_name => liker_id,
		    :user_phone => liker.phone_number,
		    :user_id => liker_id,
		    :activity_user_name => liked.try(:name),
		    :activity_user_id => liked_id,
		    :feed_id => feed_activity.feed_id,
		    :feed_name => feed_activity.feed.try(:name),
		    :venue_id => feed_activity.venue_id,
		    :venue_name => feed_activity.venue.try(:name),

		}
		

		notification = self.store_new_message_notification(payload, notification_type)
		payload[:notification_id] = notification.id

		if liked.push_token
		  count = Notification.where(user_id: liked_id, read: false, deleted: false).count
		  APNS.send_notification(liked.push_token, { :priority =>10, :alert => message, :content_available => 1, :other => payload, :badge => count})
		end

	end

	def store_new_message_notification(payload, notification_type)
		notification = {
		  :payload => payload,
		  :gcm => liked.gcm_token.present?,
		  :apns => liked.push_token.present?,
		  :response => notification_payload,
		  :user_id => liked_id,
		  :read => false,
		  :message => notification_type,
		  :deleted => false
		}
		Notification.create(notification)
	end

	def notification_payload
	  	nil
	end	
end