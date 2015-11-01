class FeedUser < ActiveRecord::Base
	belongs_to :user
	belongs_to :feed
	validates :user_id, presence: true


	has_one :feed_activity, :dependent => :destroy

	after_create :new_user_notification
	after_create :create_feed_acitivity

	def create_feed_acitivity
		FeedActivity.create!(:feed_id => feed_id, :activity_type => "new member", :feed_user_id => self.id, :user_id => self.user_id, :adjusted_sort_position => (self.created_at + 2.hours).to_i)
	end

	def new_user_notification
		begin
			if FeedUser.where("feed_id = ? AND user_id =?", feed.id, feed.user.id).first.is_subscribed == true && feed.user.id != self.user.id
				self.send_new_user_notification
			end
		rescue
			puts "List has no admin"
		end
	end

	def send_new_user_notification
		payload = {
		    :object_id => self.id, 
		    :type => 'added_list_notification', 
		    :user_id => user.id,
		    :user_name => user.name,
		    :feed_id => feed.id,
		    :feed_name => feed.name

		}

		alert = "#{user.name} added your #{feed.name} List"

		notification = self.store_new_user_notification(payload, feed.user, "new list member")
		payload[:notification_id] = notification.id

		if feed.user.push_token
		  count = Notification.where(user_id: feed.user.id, read: false, deleted: false).count
		  APNS.send_notification(feed.user.push_token, { :priority =>10, :alert => alert, :content_available => 1, :other => payload, :badge => count})
		end

	end

	def store_new_user_notification(payload, user, type)
		notification = {
		  :payload => payload,
		  :gcm => feed.user.gcm_token.present?,
		  :apns => feed.user.push_token.present?,
		  :response => notification_payload,
		  :user_id => feed.user.id,
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
