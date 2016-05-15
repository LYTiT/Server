class FeedUser < ActiveRecord::Base
	belongs_to :user
	belongs_to :feed
	validates :user_id, presence: true

	has_one :activity, :dependent => :destroy

	after_create :delayed_new_user_notification_and_activity

	def update_interest_score(value)
		#value = 0.1 for opening foreign feed
		#value = 0.2 for opening own feed
		#value = 0.05 for opening venue page of underlying feed
		self.increment!(:interest_score, value)
	end

	def delayed_new_user_notification_and_activity
		self.delay(:priority => -2).new_user_notification_and_activity 
	end

	def new_user_notification_and_activity
		if user != nil

			a = Activity.create!(:activity_type => "new_member", :feed_id => feed.id, :feed_details => feed.partial, :user_id => user.id, :user_details => user.partial,
				:feed_user_details => {:id => self.id}, :adjusted_sort_position => (self.created_at).to_i, :feed_user_id => self.id)
			
			ActivityFeed.create!(:feed_id => feed_id, :activity_id => a.id)

			feed_creator = FeedUser.where("feed_id = ? AND user_id =?", feed.id, feed.user_id).first
			feed_inviter = FeedInvitation.where("feed_id = ? AND invitee_id = ?", feed_id, user_id).first
			if (feed_creator != nil and feed_creator.is_subscribed == true) && feed_creator.user_id != user.id
				self.send_new_user_notification(feed_creator.user, true)
			end

			if (feed_inviter != nil and feed_inviter.inviter_id != feed_creator.user_id) && feed_inviter.inviter_id != user.id
				self.send_new_user_notification(feed_inviter.inviter, false)
			end
		end
	end

	def send_new_user_notification(receiver, is_creator)
		payload = {
			:intended_for => receiver.id,
		    :object_id => self.id, 
		    :type => 'added_list_notification', 
		    :user_id => user.id,
		    :user_name => user.name,
			:fb_id => user.facebook_id,
			:fb_name => user.facebook_name, 
		    :feed_id => feed.id,
		    :feed_name => feed.name,
		    :feed_color => feed.feed_color,
		    :list_creator_id => feed.user_id,
		    :activity_id => self.activity.id

		}

		if is_creator == true
			alert = "#{user.name} joined your #{feed.name} List"
		else
			alert = "#{user.name} joined #{feed.name}"
		end

		notification = self.store_new_user_notification(payload, receiver, "new list member")
		payload[:notification_id] = notification.id

		if receiver.push_token && receiver.active == true
		  count = Notification.where(user_id: receiver.id, read: false, deleted: false).count
		  APNS.send_notification(receiver.push_token, { :priority =>10, :alert => alert, :content_available => 1, :other => payload, :badge => count})
		end
	end

	def store_new_user_notification(payload, user, type)
		notification = {
		  :payload => payload,
		  :gcm => user.gcm_token.present?,
		  :apns => user.push_token.present?,
		  :response => notification_payload,
		  :user_id => user.id,
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
