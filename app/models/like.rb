class Like < ActiveRecord::Base
	belongs_to :liker, class_name: "User" 
	belongs_to :liked, class_name: "User"
	
	belongs_to :feed_venue

	belongs_to :activity

	validates :liker_id, presence: true
	validates :liked_id, presence: true

	after_create :new_like_notification

	def new_like_notification
		if activity.user_id != liker_id
			self.delay(:priority => -1).send_new_like_notification
		end
	end

	def send_new_like_notification
		if activity.activity_type == "added_venue"
			payload_type = "added_venue_like_notification"
			message = "#{liker.name} liked your added venue to #{activity.feed.name}"
			notification_type = "added_venue_like"
		else
			payload_type = "share_like_notification"
			message = "#{liker.name} liked your shared moment in #{activity.feed.name}"
			notification_type = "share_like"
		end

		payload = {
			:intended_for => liked.id,
		    :object_id => self.id, 
		    :type => "like_notification",
		    :activity_id => activity.id,
		    :activity_type => activity.activity_type,
		    :media_type => activity.venue_comment.try(:media_type),
		    :user_name => liker.name,
		    :user_phone => liker.phone_number,
		    :user_id => liker_id,
		    :fb_id => liker.facebook_id,
		    :fb_name => liker.facebook_name,
		    :activity_user_name => liked.try(:name),
		    :activity_user_id => liked_id,
		    :feed_id => activity.feed_id,
		    :feed_name => activity.feed.try(:name),
		    :feed_color => activity.feed.feed_color,
		    :list_creator_id => activity.feed.user_id,
		    :venue_id => activity.venue_id,
		    :venue_name => activity.venue.try(:name),
		    :num_likes => activity.num_likes

		}
		

		notification = self.store_new_message_notification(payload, notification_type)
		payload[:notification_id] = notification.id

		if liked.push_token && liked.active == true
		  count = Notification.where(user_id: liked_id, read: false, deleted: false).count
		  APNS.send_notification(liked.push_token, { :priority =>10, :alert => message, :content_available => 1, :other => payload, :badge => count})
		end

	end

	def store_new_message_notification(payload, notification_type)
		notification = {
		  :payload => payload,
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