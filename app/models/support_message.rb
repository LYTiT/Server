class SupportMessage < ActiveRecord::Base
	belongs_to :support_issue
	belongs_to :user

	after_create :new_message_notification

	def new_message_notification
		if user.is_admin? == true
			self.send_new_message_notification(support_issue.user)
		else
			support_issue.update_columns(latest_message_time: Time.now)
		end
	end

	def send_new_message_notification(support_user)
		payload = {
			:intended_for => support_user.id,
		    :object_id => self.id, 
		    :type => 'support_notification',
		    :support_issue_id => support_issue_id,
		    :chat_message => self.message,
		    :user_id => user_id,
		}

		type = "New support message"
		if Notification.where(user_id: support_user.id, message: type, read: false, deleted: false).count == 0
			notification = self.store_new_message_notification(payload, support_user, type)
			payload[:notification_id] = notification.id
		end
		
		if self.message.first(26) == "It appears you have posted"
			alert = "Team Lytit sent you an important message"				
		else
			alert = "Team Lytit responded to your message"
		end

		if support_user.push_token && support_user.active == true
		  count = Notification.where(user_id: support_user.id, read: false, deleted: false).count
		  APNS.send_notification(support_user.push_token, { :priority =>10, :alert => alert, :content_available => 1, :other => payload, :badge => count, :sound => 'default'})
		end

	end

	def store_new_message_notification(payload, support_user, type)
		notification = {
		  :payload => payload,
		  :gcm => support_user.gcm_token.present?,
		  :apns => support_user.push_token.present?,
		  :response => notification_payload,
		  :user_id => support_user.id,
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