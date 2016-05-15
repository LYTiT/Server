class Announcement < ActiveRecord::Base
	validates :news, presence: true
	#validates_inclusion_of :send_to_all?, in: [true, false]

	has_many :announcement_users
	has_many :users, through: :announcement_users

	after_save :new_announcement

	#------------------------------------NOTE-------------------------------------------->
	#We use an announcement message to relay over the url of a new request background image.
	#First have to create an Announcement with the amazon-url of the image to be used in the 'news' field
	#If the update is occuring for all users simply set 'send_to_all' == TRUE in the admin tool and save
	#the outgoing Anouncement. Otherwise do not change 'send_to_all', save the Announcement, open up
	#the rails console, create an array of user ids of who should receive the update and run '(your announcement).target_announcement(user_ids)'
	#followed by '(your announcement).surprise_image_update(update)' which will send the announcement out.
	#------------------------------------------------------------------------------------>


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
			self.delay(:priority => -2).send_new_announcement(audience.to_a, nil, nil)
		end
	end

	def surprise_image_update(update)
		if self.send_to_all == true
			audience = User.all
		else
			audience = users
		end

		if audience.count > 0
			self.delay(:priority => -2).send_new_announcement(audience.to_a, nil, update)
		end
	end


	def send_new_announcement(members, for_lumen_games, for_background_update)
		for member in members
			payload = {
				:intended_for => member.id,
				:object_id => self.id,
				:type => 'announcement_notification', 
				:user_id => member.id,
				:additional => for_lumen_games,
				:announcement_news => self.news,
				:announcement_title => self.title,
				:surprise_image => for_background_update
			}
			message = "#{self.title}"
			notification = self.store_new_announcement(payload, member, message)
			payload[:notification_id] = notification.id

			if member.push_token && member.active == true
				count = Notification.where(user_id: member.id, read: false, deleted: false).count
				APNS.send_notification(member.push_token, {:priority =>10, :alert => message, :content_available => 1, :other => payload, :badge => count})
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
			:deleted => false,
			:responded_to => false
		}
		Notification.create(notification)
	end

	def notification_payload
		nil
	end


end