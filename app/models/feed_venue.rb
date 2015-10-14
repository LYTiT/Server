class FeedVenue < ActiveRecord::Base
	belongs_to :feed
	belongs_to :user
	belongs_to :venue

	has_one :feed_activity, :dependent => :destroy

	after_create :new_venue_notification
	after_create :create_feed_acitivity

	def create_feed_acitivity
		FeedActivity.create!(:feed_id => feed_id, :activity_type => "added venue", :feed_venue_id => self.id, :venue_id => self.venue_id, :user_id => self.user_id, :adjusted_sort_position => (self.created_at + 2.hours).to_i)
	end

	def new_venue_notification
		feed_members = feed.feed_users

		for feed_user in feed_members
			if feed_user.is_subscribed == true && (feed_user.user_id != self.user_id && feed_user.user_id != nil)
				#might have to do a delay here/run on a seperate dyno
				begin
					self.delay.send_new_venue_notification(feed_user.user)
				rescue
					puts "Nil User encountered!"
				end
			end
		end
	end

	def send_new_venue_notification(member)
		payload = {
		    :object_id => self.id, 
		    :type => 'added_place_notification', 
		    :user_id => user_id,
		    :user_name => user.name,
		    :feed_id => feed_id,
		    :feed_name => feed.name,
		    :venue_id => venue_id,
		    :venue_name => venue.name,
		    :added_note => description

		}

		#A feed should have only 1 new chat message notification contribution to the badge count thus we create a chat notification only once,
		#when there is an unread message
		type = "#{venue.name} has been added to #{self.feed.name}"

		notification = self.store_new_venue_notification(payload, member, type)
		payload[:notification_id] = notification.id

		if member.push_token
		  count = Notification.where(user_id: member.id, read: false, deleted: false).count
		  APNS.send_notification(member.push_token, { :priority =>10, :alert => type, :content_available => 1, :other => payload, :badge => count})
		end

	end

	def store_new_venue_notification(payload, member, type)
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