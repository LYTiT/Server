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
		MomentRequest.in_bounds(search_box).where("expiration >= ? AND user_id != ?", Time.now, u_id).includes(:venue)
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

	def notify_requesters_of_response(vc)
		requesters_ids = "SELECT user_id FROM moment_request_users WHERE moment_request_id = #{self.id}"
		requesters = User.where("id IN (#{requesters_ids})") 

		if vc.entry_type == "lytit_post"
			payload = {
				:object_id => vc.id,
				:type => 'moment_request_response_notification',
				:content_origin => "lytit",
				:user_id => vc.user_details["id"],
				:user_name => vc.user_details["name"],
				:media_type => vc.lytit_post["media_type"],
				:media_dimensions => vc.lytit_post["media_dimensions"],
				:image_url_1 => vc.lytit_post["image_url_1"],
				:image_url_2 => vc.lytit_post["image_url_2"],
				:image_url_3 => vc.lytit_post["image_url_3"],
				:video_url_1 => vc.lytit_post["video_url_1"],
				:video_url_2 => vc.lytit_post["video_url_2"],
				:video_url_3 => vc.lytit_post["video_url_3"],
				:created_at => vc.lytit_post["created_at"],

				:venue_id => self.venue_id,
				:venue_name => self.venue.name,
				:venue_address => self.venue.address,
				:venue_city => self.venue.city,
				:venue_country => self.venue.country,
				:latitude => self.venue.latitude,
				:longitude => self.venue.longitude
		    }				    
		end

		if vc.entry_type == "instagram"
			payload = {
				:object_id => vc.id,
				:type => 'moment_request_response_notification',
				:content_origin => "instagram",
				:instagram_id => vc.instagram["instagram_id"],
				:media_type => vc.instagram["media_type"],
				:media_dimensions => vc.instagram["media_dimensions"],
				:image_url_1 => vc.instagram["image_url_1"],
				:image_url_2 => vc.instagram["image_url_2"],
				:image_url_3 => vc.instagram["image_url_3"],
				:video_url_1 => vc.instagram["video_url_1"],
				:video_url_2 => vc.instagram["video_url_2"],
				:video_url_3 => vc.instagram["video_url_3"],
				:created_at => vc.instagram["created_at"],		    
				:thirdparty_username => vc.instagram["instagram_user"]["name"],
				:thirdparty_user_id => vc.instagram["instagram_user"]["instagram_id"],
				:profile_image_url => vc.instagram["instagram_user"]["profile_image_url"],
			
				:venue_id => self.venue_id,
				:venue_name => self.venue.name,
				:venue_address => self.venue.address,
				:venue_city => self.venue.city,
				:venue_country => self.venue.country,
				:latitude => self.venue.latitude,
				:longitude => self.venue.longitude
		    }
		end

		for requester in requesters
			if requester != nil
				payload[:intended_for] = requester.id
				type = "Moment Request Response"
				notification = self.store_new_notification(payload, requester, type)
				payload[:notification_id] = notification.id
				
				alert = "Someone responded to your request at #{self.venue.name}"
				
				if requester.push_token && requester.active == true
					count = Notification.where(user_id: requester.id, read: false, deleted: false).count
					APNS.send_notification(requester.push_token, { :priority =>10, :alert => alert, :content_available => 1, :other => payload, :badge => count})
				end
					 
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