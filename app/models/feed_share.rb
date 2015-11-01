class FeedShare < ActiveRecord::Base
	belongs_to :feed
	belongs_to :user
	belongs_to :venue_comment

	has_one :feed_activity, :dependent => :destroy


	def self.implicit_creation(instagram_details, vc_id, u_id, target_feed_ids, comment)
		if vc_id == nil
			vc_id = VenueComment.convert_instagram_details_to_vc(instagram_details).id
		end

		vc_venue = VenueComment.where("id = ?", vc_id).includes(:venue).first.venue

		for target_feed_id in target_feed_ids
			fs = FeedShare.create!(:user_id => u_id, :venue_comment_id => vc_id, :feed_id => target_feed_id)
			fa = FeedActivity.create!(:feed_share_id => fs.id, :activity_type => "shared moment", :feed_id => target_feed_id, :user_id => u_id, :venue_id => vc_venue.id, :adjusted_sort_position => fs.created_at.to_i)
			if comment != nil && comment != ""
				fac = FeedActivityComment.create!(:feed_activity_id => fa.id, :user_id => u_id, :comment => comment)
				fa.update_comment_parameters(Time.now, u_id)
			end
			fs.new_feed_share_notification
		end
	end

	def new_feed_share_notification
		feed_users = FeedUser.where("feed_id = ?", feed_id)
		for feed_user in feed_users
			if feed_user.is_subscribed == true && (feed_user.user_id != self.user_id && feed_user.user != nil)
				self.send_new_feed_share_notification(feed_user.user)
			end
		end
	end

	def send_new_feed_share_notification(member)
		payload = {
		    :object_id => self.id, 
		    :activity_id => feed_activity.id,
		    :type => 'share_notification', 
		    :user_id => user_id,
		    :user_name => user.name,
		    :user_phone => user.phone_number,
		    :feed_id => feed_id,
		    :feed_name => feed.name
		}


		type = "Feed share"

		notification = self.store_new_shared_venue_comment_notification(payload, member, type)
		payload[:notification_id] = notification.id

		preview = "#{user.name} shared a Moment with #{feed.name}"
		if member.push_token
		  count = Notification.where(user_id: member.id, read: false, deleted: false).count
		  APNS.send_notification(member.push_token, { :priority =>10, :alert => preview, :content_available => 1, :other => payload, :badge => count})
		end

	end

	def store_new_shared_venue_comment_notification(payload, member, type)
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