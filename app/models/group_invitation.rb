class GroupInvitation < ActiveRecord::Base
	belongs_to :igroup, class_name: "Group"
	belongs_to :invited, class_name: "User"
	belongs_to :host, class_name: "User"
	validates :igroup_id, presence: true
	validates :invited_id, presence: true



	after_create :new_group_invitation_notification

	def new_group_invitation_notification
		self.delay.send_new_group_invitation_notification
	end

	def send_new_group_invitation_notification
		payload = {
		    :object_id => self.id, 
		    :type => 'new_invitation', 
		    :user_id => invited_id
		}
		message = "#{host.name} has invited you to add #{igroup.name} to your Placelists"
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
	    :group => {
	      :id => igroup.id,
	      :name => igroup.name,
	      :group_password => igroup.password
	  	},
	  	:user => {
	      :id => host.id,
	      :name => host.name,
	    },
	    :invitation_id => self.id 
	  }
	end

end