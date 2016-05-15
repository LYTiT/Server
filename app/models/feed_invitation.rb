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
			:intended_for => invitee.id,
		    :object_id => self.id, 
		    :type => 'invited_list_notification', 
		    :user_id => inviter.id,
		    :user_name => inviter.name,
		    :user_phone => inviter.phone_number,
		   	:fb_id => inviter.facebook_id,
      		:fb_name => inviter.facebook_name,
		    :feed_id => feed.id,
		    :feed_name => feed.name,
		    :feed_color => feed.feed_color,
		    :list_creator_id => feed.user_id

		}

		
		type = "List invitation"
		notification = self.store_new_invitation_notification(payload, invitee, type)
		payload[:notification_id] = notification.id
		
		alert = "#{inviter.name} invited you to join the #{feed.name} List"
		
		if invitee.push_token && invitee.active == true
		  count = Notification.where(user_id: invitee_id, read: false, deleted: false).count
		  APNS.send_notification(invitee.push_token, { :priority =>10, :alert => alert, :content_available => 1, :other => payload, :badge => count})
		end

	end

	def store_new_invitation_notification(payload, invitee, type)
		notification = {
		  :payload => payload,
		  :gcm => invitee.gcm_token.present?,
		  :apns => invitee.push_token.present?,
		  :response => nil,
		  :user_id => invitee.id,
		  :read => false,
		  :message => type,
		  :deleted => false
		}
		Notification.create(notification)
	end

end