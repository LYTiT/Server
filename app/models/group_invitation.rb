class GroupInvitation < ActiveRecord::Base
	belongs_to :igroup, class_name: "Group"
	belongs_to :invited, class_name: "User"
	belongs_to :host, class_name: "User"
	validates :igroup_id, presence: true
	validates :invited_id, presence: true

	after_create :new_group_invitation_notification

	def new_group_invitation_notification
		if invited.version_compatible?("3.0.1") == true
			self.delay.send_new_group_invitation_notification
		end
	end

	def send_new_group_invitation_notification
		payload = {
		    :object_id => self.id, 
		    :type => 'new_invitation', 
		    :user_id => invited_id
		}
		message = "#{host.name} has invited you to join #{group.name}"
		notification = self.store_new_group_invitation_notification(payload, invited, message)
		payload[:notification_id] = notification.id

		if invited.push_token
		  count = Notification.where(user_id: invited_id, read: false).count
		  APNS.delay.send_notification(invited.push_token, { :priority =>10, :alert => message, :content_available => 1, :other => payload, :badge => count})
		end

		if invited.gcm_token
		  gcm_payload = payload.dup
		  gcm_payload[:message] = message
		  options = {
		    :data => gcm_payload
		  }
		  request = HiGCM::Sender.new(ENV['GCM_API_KEY'])
		  request.send([invited.gcm_token], options)
		end

	end

	def store_new_group_invitation_notification(payload, user, message)
		notification = {
		  :payload => payload,
		  :gcm => user.gcm_token.present?,
		  :apns => user.push_token.present?,
		  :response => notification_payload,
		  :user_id => user.id,
		  :read => false,
		  :message => message,
		  :deleted => false
		}
		Notification.create(notification)
	end

	def notification_payload
	  {
	    :invitation => {
	      :grp_id => igroup.id,
	      :grp_name => igroup.name,
	      :hst_id => host.id,
	      :hst_name => host.name,
	    }
	    
	  }
	end

end