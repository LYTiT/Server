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
		for member in members
			if member.version_compatible?("3.1.0") == true #note only account for iPhone users not Android! They will be on a differenet version
				payload = {
					:object_id => self.id,
					:type => 'announcement', 
					:user_id => member.id
				}
				message = "#{self.news}"
				notification = self.store_new_announcement(payload, member, message)
				payload[:notification_id] = notification.id

				if member.push_token
					count = Notification.where(user_id: member.id, read: false).count
					APNS.delay.send_notification(member.push_token, {:priority =>10, :alert => message, :content_available => 1, :other => payload, :badge => count})
				end

				if member.gcm_token
					gcm_payload = payload.dup
					gcm_payload[:message] = message
					options = {
						:data => gcm_payload
					}
					request = HiGCM::Sender.new(ENV['GCM_API_KEY'])
					request.send([member.gcm_token], options)
				end
			end
		end
	end

	def store_new_announcement(payload, receiver, message)
		notification = {
			:payload => payload,
			:gcm => receiver.gcm_token.present?,
			:apns => receiver.push_token.present?,
			:response => notification_payload,
			:user_id => receiver.id,
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