class FeedInvitation < ActiveRecord::Base
	belongs_to :inviter, class_name: "User" 
	belongs_to :invitee, class_name: "User"
	belongs_to :feed

	validates :inviter_id, presence: true
	validates :invitee_id, presence: true

	after_create :new_invitation_notification

	def new_invitation_notification			
		self.send_invitation_notification		
	end

	def send_invitation_notification
		payload = {
		    :object_id => self.id, 
		    :type => 'invited_list_notification', 
		    :user_id => user.id,
		    :user_name => user.name,
		    :user_phone => user.phone_number,
		    :feed_id => feed.id,
		    :feed_name => feed.name,
		    :feed_color => feed.feed_color

		}

		
		type = "List invitation"
		notification = self.store_new_invitation_notification(payload, invitee, type)
		payload[:notification_id] = notification.id
		
		alert = "#{inviter.name} invited you to add the #{feed.name} List"
		
		if invitee.push_token
		  count = Notification.where(user_id: invitee_id, read: false, deleted: false).count
		  APNS.send_notification(invitee.push_token, { :priority =>10, :alert => alert, :content_available => 1, :other => payload, :badge => count})
		end

	end

	def store_new_invitation_notification(payload, user, type)
		notification = {
		  :payload => payload,
		  :gcm => feed.user.gcm_token.present?,
		  :apns => feed.user.push_token.present?,
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