class SupportMessage < ActiveRecord::Base
	belongs_to :support_issue

	after_create :new_message_notification

	def new_message_notification
		user = self.support_issue.user
		if user.is_admin? == true
			self.send_new_message_notification(user)
		else
			support_issue.update_columns(latest_message_time: Time.now)
		end
	end

	def send_new_message_notification(user)
		payload = {
		    :object_id => self.id, 
		    :type => 'support_notification',
		    :support_issue_id => support_issue_id,
		    :chat_message => self.message,
		    :user_id => user.id,
		}

		type = "New support message"
		if Notification.where(user_id: user.id, message: type, read: false, deleted: false).count == 0
			notification = self.store_new_message_notification(payload, user, type)
			payload[:notification_id] = notification.id
		end
		
		preview = "Team LYTiT responded to your outreach"

		if user.push_token
		  count = Notification.where(user_id: user.id, read: false, deleted: false).count
		  APNS.send_notification(user.push_token, { :priority =>10, :alert => preview, :content_available => 1, :other => payload, :badge => count, :sound => 'default'})
		end

	end

	def store_new_message_notification(payload, user, type)
		notification = {
		  :payload => payload,
		  :gcm => user.gcm_token.present?,
		  :apns => user.push_token.present?,
		  :response => notification_payload,
		  :user_id => user.id,
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