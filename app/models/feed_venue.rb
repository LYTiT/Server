class FeedVenue < ActiveRecord::Base
	belongs_to :feed
	belongs_to :user
	belongs_to :venue
	validates :venue_id, presence: true

	has_one :activity, :dependent => :destroy

	after_create :delayed_new_venue_notification_and_activity


	def delayed_new_venue_notification_and_activity
		self.delay(:priority => -3).new_venue_notification_and_activity
	end

	def new_venue_notification_and_activity
		if feed != nil
			if user == nil
				user = feed.user
				if user != nil
					user_name = feed.user.name
					user_phone_number = feed.user.phone_number
					user_facebook_id = feed.user.facebook_id
					user_facebook_name = feed.user.facebook_name
				else
					user_name = nil
					user_phone_number = nil
					user_facebook_id = nil
					user_facebook_name = nil
				end
			else
				user_name = self.user.name
				user_phone_number = self.user.phone_number
				user_facebook_id = self.user.facebook_id
				user_facebook_name = self.user.facebook_name
			end		

			a = Activity.create!(:activity_type => "added_venue", :feed_id => feed.id, :feed_details => feed.partial, :user_id => user.id, :user_details => user.partial,
				:venue_id => venue.id, :venue_details => venue.partial, :feed_venue_details => {:id => self.id, :added_note => self.description}, 
				:adjusted_sort_position => (self.created_at).to_i, :feed_venue_id => self.id)

			ActivityFeed.create!(:feed_id => feed_id, :activity_id => a.id)
			feed_members = feed.feed_users

			for feed_user in feed_members
				if feed_user.is_subscribed == true && (feed_user.user_id != self.user_id && feed_user.user != nil)
					self.send_new_venue_notification(feed_user.user)
				end
			end
		end
	end

	def send_new_venue_notification(member)
		payload = {
		    :object_id => self.id, 
		    :type => 'added_place_notification', 
		    :user_id => user_id,
		    :user_name => user.try(:name),
		    :fb_id => user.try(:facebook_id),
		    :fb_name => user.try(:facebook_name),
		    :feed_id => feed_id,
		    :feed_name => feed.name,
		    :feed_color => feed.feed_color,
		    :venue_id => venue_id,
		    :venue_name => venue.name,
		    :added_note => description,
		    :list_creator_id => feed.user_id,
		    :activity_id => self.activity.id

		}

		#A feed should have only 1 new chat message notification contribution to the badge count thus we create a chat notification only once,
		#when there is an unread message
		type = "#{venue.name} has been added to #{self.feed.name}"

		notification = self.store_new_venue_notification(payload, member, type)
		payload[:notification_id] = notification.id

		if member.push_token && member.active == true
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