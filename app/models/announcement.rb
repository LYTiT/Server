class Announcement < ActiveRecord::Base
	validates :news, presence: true
	#validates_inclusion_of :send_to_all?, in: [true, false]

	has_many :announcement_users
	has_many :users, through: :announcement_users

	after_save :new_announcement

	def target_announcement(user_ids)
		for id in user_ids
			receipt = AnnouncementUser.new(user_id: id, announcement_id: self.id)
			receipt.save
		end
	end


	def new_announcement
		if self.send_to_all == true
			audience = User.all
		else
			audience = users
		end

		if audience.count > 0
			self.delay.send_new_announcement(audience.to_a)
		end
	end

	def send_new_announcement(members)
		for user in members
			payload = {
				:object_id => self.id,
				:type => 'announcement', 
				:user_id => user.id
			}
			message = "#{self.news}"
			notification = self.store_new_announcement(payload, user, message)
			payload[:notification_id] = notification.id

			if user.push_token && user.version_compatible?("3.1.0") == true
				count = Notification.where(user_id: user.id, read: false).count
				APNS.delay.send_notification(user.push_token, {:priority =>10, :alert => message, :content_available => 1, :other => payload, :badge => count})
			end

			if user.gcm_token && user.version_compatible?("3.1.0") == true #change to android when released
				gcm_payload = payload.dup
				gcm_payload[:message] = message
				options = {
					:data => gcm_payload
				}
				request = HiGCM::Sender.new(ENV['GCM_API_KEY'])
				request.send([user.gcm_token], options)
			end
		end
	end

	def store_new_announcement(payload, user, message)
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
			:announcement_news => self.news 
		}
	end

end