class FeedJoinRequest < ActiveRecord::Base
	belongs_to :feed
	belongs_to :user

	after_create :new_request_notification

	def accepted(response)
		if response == true
			self.update_columns(granted: true)
			FeedUser.create!(:feed_id => self.feed_id, :user_id => self.user_id, :creator => false)
			Feed.delay(:priority => -1).new_member_calibration(self.feed_id, self.user_id)
			response_notification(true)
		else
			self.update_columns(granted: false)
			response_notification(false)
		end
	end

	def new_request_notification
		list_admin = self.feed.user
		if list_admin != nil
			payload = {
			    :object_id => self.id, 
			    :type => 'list_access_request_notification', 
			    :user_id => self.user_id,
			    :user_name => self.user.name,
			   	:fb_id => self.user.facebook_id,
	      		:fb_name => self.user.facebook_name,
			    :feed_id => self.feed_id,
			    :feed_name => self.feed.name,
			    :feed_color => self.feed.feed_color,
			    :preview_image_url => self.feed.preview_image_url,
			    :note => self.note
			}
		
			type = "List Join Request"
			notification = self.store_new_notification(payload, list_admin, type)
			payload[:notification_id] = notification.id
			
			alert = "#{self.user.name} requested to join your #{feed.name} List"
			
			if list_admin.push_token && list_admin.active == true
				count = Notification.where(user_id: list_admin.id, read: false, deleted: false).count
				APNS.send_notification(list_admin.push_token, { :priority =>10, :alert => alert, :content_available => 1, :other => payload, :badge => count})
			end
		end
	end

	def response_notification(response)
		requester = self.user

		if response == true
			alert = "Your request to join the #{feed.name} List was approved by its admin"
		else
			alert = "Your request to join the #{feed.name} List was rejected by its admin"
		end

		if requester != nil
			payload = {
			    :object_id => self.id, 
			    :type => 'list_access_request_accepted', 
			    :list_acces_request_accepted => response,
			    :feed_id => self.feed_id,
			    :feed_name => self.feed.name,
			    :feed_color => self.feed.feed_color,
			    :preview_image_url => self.feed.preview_image_url
			}

			type = "Request response"
			notification = self.store_new_notification(payload, requester, type)
			payload[:notification_id] = notification.id			
			
			if requester.push_token && requester.active == true
				count = Notification.where(user_id: requester.id, read: false, deleted: false).count
				APNS.send_notification(requester.push_token, { :priority =>10, :alert => alert, :content_available => 1, :other => payload, :badge => count})
			end
		end
	end		



	def store_new_notification(payload, notification_user, type)
		notification = {
		  :payload => payload,
		  :gcm => notification_user.gcm_token.present?,
		  :apns => notification_user.push_token.present?,
		  :response => nil,
		  :user_id => notification_user.id,
		  :read => false,
		  :message => type,
		  :deleted => false
		}
		Notification.create(notification)
	end

end