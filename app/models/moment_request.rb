class MomentRequest < ActiveRecord::Base
	acts_as_mappable :default_units => :kms,
	             :default_formula => :sphere,
	             :distance_field_name => :distance,
	             :lat_column_name => :latitude,
	             :lng_column_name => :longitude

	belongs_to :user
	belongs_to :venue
	has_many :moment_request_users, :dependent => :destroy 

	def MomentRequest.get_surrounding_request(lat, long, u_id)
		search_box = Geokit::Bounds.from_point_and_radius([lat, long], 0.2, :units => :kms)
		MomentRequest.in_bounds(search_box).where("expiration <= ? AND user_id != ?", Time.now, u_id).includes(:venue)
	end

	def MomentRequest.fulfilled_by_post(request_time, post_origin="lytit_post") 
		if post_origin == "lytit_post"
			if request_time != nil and request_time >= Time.now - 1.hour
				return true
			else
				return false
			end
		else
			if request_time != nil and request_time >= Time.now - 30.minutes
				return true
			else
				return false
			end
		end
	end
=begin
	def notify_requesters_of_response(vc)
		requesters_ids = "SELECT user_id FROM moment_request_users WHERE request_id = #{self.id}"
		requesters = User.where("id IN (#{requesters_ids})") 

		for requester in requesters
			if requester != nil



			if vc.entry_type == "lytit_post"
				
				:content_origin "lytit",
				:user_id vc.user_details["id"],
				:user_name vc.user_details["name"],
				:id vc.lytit_post["id"],
			    :media_type vc.lytit_post["media_type"],
			    :media_dimensions vc.lytit_post["media_dimensions"],
			    :image_url_1 vc.lytit_post["image_url_1"],
			    :image_url_2 vc.lytit_post["image_url_2"],
			    :image_url_3 vc.lytit_post["image_url_3"],
			    :video_url_1 vc.lytit_post["video_url_1"],
			    :video_url_2 vc.lytit_post["video_url_2"],
			    :video_url_3 vc.lytit_post["video_url_3"],
			    :created_at vc.lytit_post["created_at"]	
			end

			if vc.entry_type == "instagram"
				json.content_origin "instagram"
				json.id comment.id
			    json.instagram_id comment.instagram["instagram_id"]
			    json.media_type comment.instagram["media_type"]
			    json.media_dimensions comment.instagram["media_dimensions"]
			    json.image_url_1 comment.instagram["image_url_1"]
			    json.image_url_2 comment.instagram["image_url_2"]
			    json.image_url_3 comment.instagram["image_url_3"]
			    json.video_url_1 comment.instagram["video_url_1"]
			    json.video_url_2 comment.instagram["video_url_2"]
			    json.video_url_3 comment.instagram["video_url_3"]
			    json.created_at comment.instagram["created_at"]		    
			    json.thirdparty_username comment.instagram["instagram_user"]["name"]
			    json.thirdparty_user_id comment.instagram["instagram_user"]["instagram_id"]
			    json.thirdparty_user_profile_image_url comment.instagram["instagram_user"]["profile_image_url"]
			end



				payload = {
				    :object_id => self.id, 
				    :type => 'moment_request_response_notification',
				    :venue_id
				    :venue_name
				    :venue_address
				    :venue_city
				    :venue_country
				    :latitude
				    :longitude



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
			
				type = "Moment Request Response"
				notification = self.store_new_invitation_notification(payload, list_admin, type)
				payload[:notification_id] = notification.id
				
				alert = "A response has come in t"
				
				if requester.push_token && requester.active == true
					count = Notification.where(user_id: requester.id, read: false, deleted: false).count
					APNS.send_notification(requester.push_token, { :priority =>10, :alert => alert, :content_available => 1, :other => payload, :badge => count})
				end
					 
			end
		end
	end

	def store_new_notification(payload, notification_usre, type)
		notification = {
		  :payload => payload,
		  :gcm => notification_usre.gcm_token.present?,
		  :apns => notification_usre.push_token.present?,
		  :response => nil,
		  :user_id => notification_usre.id,
		  :read => false,
		  :message => type,
		  :deleted => false
		}
		Notification.create(notification)
	end
=end
end