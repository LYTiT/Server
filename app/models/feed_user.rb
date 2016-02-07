class FeedUser < ActiveRecord::Base
	belongs_to :user
	belongs_to :feed
	validates :user_id, presence: true


	has_one :activity, :dependent => :destroy

	after_create :delayed_new_user_notification_and_activity

	def delayed_new_user_notification_and_activity
		self.delay.new_user_notification_and_activity 
	end


	def new_user_notification_and_activity
		a = Activity.create!(:feed_id => feed_id, :feed_name => feed.name, :feed_color => feed.feed_color, :activity_type => "new_member", :feed_user_id => self.id, 
			:user_id => self.user_id, :user_name => user.name, :user_phone => user.phone_number, :user_facebook_id => user.facebook_id, :user_facebook_name => user.facebook_name, 
			:adjusted_sort_position => (self.created_at).to_i)
		
		ActivityFeed.create!(:feed_id => feed_id, :activity_id => a.id)

		feed_creator = FeedUser.where("feed_id = ? AND user_id =?", feed.id, feed.user.id).first
		feed_inviter = FeedInvitation.where("feed_id = ? AND invitee_id = ?", feed_id, user_id).inviter
		if feed_creator != nil and feed_creator.is_subscribed == true
			self.send_new_user_notification(feed_creator.user, true)
		end

		if feed_inviter != nil and feed_inviter != feed_creator
			self.send_new_user_notification(feed_inviter.inviter, false)
		end
	end

	def send_new_user_notification(receiver, is_creator)
		payload = {
		    :object_id => self.id, 
		    :type => 'added_list_notification', 
		    :user_id => user.id,
		    :user_name => user.name,
		    :feed_id => feed.id,
		    :feed_name => feed.name,
		    :feed_color => feed.feed_color,
		    :activity_id => self.activity.id

		}

		if is_creator == true
			alert = "#{user.name} joined your #{feed.name} List"
		else
			alert = "#{user.name} joined #{feed.name}"
		end

		notification = self.store_new_user_notification(payload, feed.user, "new list member")
		payload[:notification_id] = notification.id

		if receiver.push_token && receiver.user.active == true
		  count = Notification.where(user_id: receiver.user.id, read: false, deleted: false).count
		  APNS.send_notification(receiver.user.push_token, { :priority =>10, :alert => alert, :content_available => 1, :other => payload, :badge => count})
		end
	end

	def store_new_user_notification(payload, user, type)
		notification = {
		  :payload => payload,
		  :gcm => receiver.gcm_token.present?,
		  :apns => receiver.push_token.present?,
		  :response => notification_payload,
		  :user_id => receiver.id,
		  :read => false,
		  :message => type,
		  :deleted => false
		}
		Notification.create(notification)
	end

	def notification_payload
	  	nil
	end

	def update_interest_score
		
	end


end
