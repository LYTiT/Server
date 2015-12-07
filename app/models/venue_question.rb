class VenueQuestion < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue

	has_many :venue_question_comments, :dependent => :destroy

	after_create :new_question_notification

	def new_question_notification
		live_users_on_location = venue.live_users
		for live_user_on_location in live_users_on_location
			send_new_question_notification(live_user_on_location.user)
		end 
	end

	def self.send_new_question_notification(live_user)
		payload = {
		    :object_id => self.id,
		    :type => 'question_notification', 
		    :question => question,
		    :venue_id => venue_id,
		    :venue_id => venue.name,
		    :user_id => user_id,
		    :user_name => user.try(:name),
		    :user_phone => user.try(:phone_number)
		}


		type = "venue_question/#{self.id}"

		notification = self.store_new_topic_notification(payload, live_user, type)
		payload[:notification_id] = notification.id

		preview = "Someone posted a question to your location."

		if live_user.push_token && live_usr.active == true
		  count = Notification.where(user_id: live_user.id, read: false, deleted: false).count
		  APNS.send_notification(live_user.push_token, { :priority =>10, :alert => preview, :content_available => 1, :other => payload, :badge => count})
		end

	end

	def store_new_topic_notification(payload, live_user, type)
		notification = {
		  :payload => payload,
		  :gcm => user.gcm_token.present?,
		  :apns => user.push_token.present?,
		  :response => nil,
		  :user_id => live_user.id,
		  :read => false,
		  :message => type,
		  :deleted => false
		}
		Notification.create(notification)
	end

end