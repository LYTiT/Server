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
				:intended_for => feed.user_id,
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
				:intended_for => requester.id,
			    :object_id => self.id, 
			    :type => 'list_access_response_notification', 
			    :list_access_request_accepted => response,
			    :feed_creator => self.feed.user.try(:name),
			    :list_creator_id => self.feed.user.try(:name),
			    :list_creator_fb_id => self.feed.user.try(:facebook_id),
			    :list_creator_fb_name => self.feed.user.try(:facebook_name),
			    :list_description => self.feed.description,
			    :list_creator_is_verified => self.feed.user.try(:is_verified),
			    :list_open => self.feed.open,
			    :list_is_private => self.feed.is_private,
			    :feed_id => self.feed_id,
			    :feed_name => self.feed.name,
			    :feed_color => self.feed.feed_color,
			    :cover_image_url => self.feed.cover_image_url,
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