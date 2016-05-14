class PostPass < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue_comment

	after_create :send_new_post_pass_notification

	def PostPass.initiate(vc)
		first_revceivers = vc.user.nearest_neighbors.where("active IS TRUE AND id != #{vc.user_id}")

		for receiver in first_revceivers
			PostPass.create!(:user_id => receiver.id, :venue_comment_id => vc.id)
		end
	end

	def pass_on
		self.update_columns(passed_on: true)
		next_users = self.select_next_users
		for next_user in next_users
			PostPass.create!(:user_id => next_user.id, :venue_comment_id => self.venue_comment_id)
		end

		admins = User.all.joins(:role).where("roles.name = ?", "Admin")
		for admin in admins
			PostPass.create!(:user_id => admin.id, :venue_comment_id => self.venue_comment_id)
		end
	end

	def terminate
		self.update_columns(passed_on: false)
		if PostPass.where("venue_comment_id = ? AND passed_on IS TRUE OR passed_on IS NULL", self.venue_comment_id).count == 0
			venue_comment.update_columns(active: false)
		end
	end

	def report
		ReportedObject.create!(:reporter_id => user_id, :venue_comment_id => venue_comment_id, :report_type => "Reported Post", :user_id => venue_comment.user_id)
	end

	def select_next_users
		previous_post_pass_user_ids = "SELECT user_id FROM post_passes WHERE venue_comment_id = #{self.venue_comment_id}"
		#post_pass_user_ids = "SELECT user_id FROM post_passes WHERE (venue_comment_id = #{self.venue_comment_id} OR passed_on IS NULL)"
		self.user.nearest_neighbors.where("id NOT IN (#{previous_post_pass_user_ids}) AND id != #{self.venue_comment.user_id} AND active IS TRUE")
	end

	def send_new_post_pass_notification
		vc = self.venue_comment
		post_pass_lifespan = 30*60 #seconds (30mins)
		
		payload = {
			:object_id => self.id,       
			:type => 'post_pass_notification',
			:venue_comment_id => vc.id,
			:user_id => vc.user_id,
			:user_name => vc.user_details["name"],
			:profile_image_url => vc.user_details["profile_image_url"],
			:media_type => vc.lytit_post["media_type"],
			:media_dimensions => vc.lytit_post["media_dimensions"],
			:reaction => vc.lytit_post["reaction"],
			:image_url_1 => vc.lytit_post["image_url_1"],
			:image_url_2 => vc.lytit_post["image_url_2"],
			:image_url_3 => vc.lytit_post["image_url_3"],
			:video_url_1 => vc.lytit_post["video_url_1"],
			:video_url_2 => vc.lytit_post["video_url_2"],
			:video_url_3 => vc.lytit_post["video_url_3"],
			:venue_id => vc.venue_details["id"],
			:venue_name => vc.venue_details["name"],
			:venue_address => vc.venue_details["address"],
			:venue_city => vc.venue_details["city"],
			:venue_country => vc.venue_details["country"],
			:latitude => vc.venue_details["latitude"],
			:longitude => vc.venue_details["longitude"],
			:content_origin => 'lytit',
			:geo_views => vc.geo_views,
			:num_views => vc.num_enlytened,
			:num_enlytened => vc.num_enlytened,
			:surprise_response_time => post_pass_lifespan
		}

		type = "post_pass/#{vc.id}/#{self.id}"
		preview = "New live Moment avaliable!"

		notification = self.store_new_notification(payload, user, type)
		payload[:notification_id] = notification.id

		if user.push_token
			count = Notification.where(user_id: user.id, read: false, deleted: false).count
			APNS.send_notification(user.push_token, { :priority =>10, :alert => preview, :content_available => 1, :other => payload, :badge => count})
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