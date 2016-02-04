class FeedVenue < ActiveRecord::Base
	belongs_to :feed
	belongs_to :user
	belongs_to :venue
	validates :venue_id, presence: true

	has_one :activity, :dependent => :destroy

	after_create :new_venue_notification_and_activity


	def new_venue_notification_and_activity
		feed = Feed.find_by_id(feed_id)
		a = Activity.create!(:feed_id => feed_id, :feed_name => feed.name, :feed_color => feed_color, :activity_type => "added_venue", :feed_venue_id => self.id, 
			:user_id => self.user_id, :user_name => self.user.name, :user_phone => user.phone_number, :venue_id => self.venue_id, :venue_name => self.venue.name, 
			:venue_instagram_location_id => self.venue.instagram_location_id, :venue_latitude => self.venue.latitude,
			:venue_longitude => self.venue.longitude, :venue_address => self.venue.address, :venue_city => self.venue.city,
			:venue_state => self.venue.state, :venue_country => self.venue.country, :venue_note => self.description,
			:adjusted_sort_position => (self.created_at).to_i)


		ActivityFeed.create!(:feed_id => feed_id, :activity_id => a.id)
		feed_members = feed.feed_users

		for feed_user in feed_members
			if feed_user.is_subscribed == true && (feed_user.user_id != self.user_id && feed_user.user != nil)
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
		    :feed_color => feed.feed_color,
		    :venue_id => venue_id,
		    :venue_name => venue.name,
		    :added_note => description,
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