class Like < ActiveRecord::Base
	belongs_to :liker, class_name: "User" 
	belongs_to :liked, class_name: "User"
	
	belongs_to :feed_venue
	belongs_to :feed_message

	validates :liker_id, presence: true
	validates :liked_id, presence: true

	after_create :new_like_notification

	def new_like_notification
		self.delay.send_new_like_notification
	end

	def send_new_like_notification
		if type == "Added Venue"
			payload_type = "added_venue_like_notification"
			message = "#{liker.name} has liked your contribution to #{feed_venue.feed.name}"
			notification_type = "Added venue like"
		else
			payload_type = "message_like_notification"
			message = "#{liker.name} has liked your shared Moment in #{feed_venue.feed.name}"
			notification_type = "Message like"
		end

		payload = {
		    :object_id => self.id, 
		    :type => payload_type,
		    :liker_id => liker_id,
		    :liker_name => liker.name,
		    :liker_phone => liker.phone_number,
		    :liked_id => liked_id,
		    :feed_id => feed_venue.try(:feed_id),
		    :feed_name => feed_venue.try(:feed).try(:name),
		    :venue_id => feed_venue.try(:venue_id),
		    :venue_name => feed_venue.try(:venue).try(:name),
		    :message_id => feed_message_id,
		    :venue_comment_id => feed_message.try(:venue_comment_id)

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
		  :gcm => user.gcm_token.present?,
		  :apns => user.push_token.present?,
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