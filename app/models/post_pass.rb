class PostPass < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue_comment

	after_create :send_new_post_pass_notification

	def pass_on
		self.update_columns(passed_on: true)
		next_users = self.select_next_users
		for next_user in next_users
			PostPass.new!(:user_id => next_user.id, :venue_comment_id => self.venue_comment_id)
		end
	end

	def terminate
		self.update_columns(passed_on: false)
	end

	def report
	end

	def select_next_users
		previous_post_pass_user_ids = "SELECT user_id FROM post_passes WHERE venue_comment_id = #{self.venue_comment_id}"
		self.user.nearest_neighbors.where("id NOT IN (#{previous_post_pass_user_ids})")
	end

	def send_new_post_pass_notification
		vc = self.venue_comment
		vc_user = vc.user
		if vc.views == 1 || (vc.views%5 == 0 && vc.views <= 20) || (vc.views%10 && vc.views > 20)
			payload = {
				:object_id => self.id,       
				:type => 'post_pass_notification',
				:id => vc.id,
				:media_type => vc.lytit_post["media_type"],
				:media_dimensions => vc.lytit_post["media_dimensions"],
				:image_url_1 => vc.lytit_post["image_url_1"],
				:image_url_2 => vc.lytit_post["image_url_2"],
				:image_url_3 => vc.lytit_post["image_url_3"],
				:video_url_1 => vc.lytit_post["video_url_1"],
				:video_url_2 => vc.lytit_post["video_url_2"],
				:video_url_3 => vc.lytit_post["video_url_3"],
				:venue_id => vc.venue_details["id"],
				:venue_name => vc.venue_details["name"],
				:latitude => vc.venue_details["latitdue"],
				:longitude => vc.venue_details["longitude"],
				:timestamp => vc.created_at,
				:content_origin => 'lytit',
				:geo_views => vc.geo_views,
				:num_views => vc.views
			}

			type = "post_pass/#{vc.id}/#{vc.views}"

			notification = self.store_new_notification(payload, vc_user, type)
			payload[:notification_id] = notification.id

			if vc_user.push_token && vc_user.active == true
				count = Notification.where(user_id: vc_user.id, read: false, deleted: false).count
				APNS.send_notification(vc_user.push_token, { :priority =>10, :alert => preview, :content_available => 1, :other => payload, :badge => count})
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