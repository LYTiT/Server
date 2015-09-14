class FeedMessage < ActiveRecord::Base
	belongs_to :user
	belongs_to :feed

	has_many :venue_comments

	after_create :new_message_notification

	def new_message_notification
		feed_members = feed.feed_users

		for feed_user in feed_members
			if feed_user.is_subscribed == true && feed_user.user.id != self.user.id
				#might have to do a delay here/run on a seperate dyno
				if self.venue_comments.first != nil
					self.delay.send_new_message_notification(feed_user.user)
				else
					self.send_new_message_notification(feed_user.user)
				end
			end
		end
	end


	def send_new_message_notification(member)
		media_url = self.venue_comments.first.image_url_1 rescue self.venue_comments.first.image_url_2
		payload = {
		    :object_id => self.id, 
		    :type => 'chat_notification', 
		    :user_id => user.id,
		    :user_name => user.name,
		    :user_phone => user.phone_number,
		    :feed_id => feed.id,
		    :feed_name => feed.name,
		    :chat_message => self.message,
		    :venue_comment_id => self.venue_comments.first.id,
		    :media_type => self.venue_comments.first.media_type,
		    :media_url => media_url

		}

		#A feed should have only 1 new chat message notification contribution to the badge count thus we create a chat notification only once,
		#when there is an unread message
		type = "New message in #{self.feed.name} List"
		if Notification.where(user_id: member.id, message: type, read: false, deleted: false).count == 0
			notification = self.store_new_message_notification(payload, member, type)
			payload[:notification_id] = notification.id
		end

		preview = "#{user.name} in"+' "'+"#{feed.name}"+'"'+":\n#{message}"
		if member.push_token
		  count = Notification.where(user_id: member.id, read: false, deleted: false).count
		  puts "Sending chat to #{member.name} whose id is #{member.id}"
		  APNS.send_notification(member.push_token, { :priority =>10, :alert => preview, :content_available => 1, :other => payload, :badge => count, :sound => 'default'})
		end

	end

	def store_new_message_notification(payload, member, type)
		notification = {
		  :payload => payload,
		  :gcm => user.gcm_token.present?,
		  :apns => user.push_token.present?,
		  :response => notification_payload,
		  :user_id => member.id,
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