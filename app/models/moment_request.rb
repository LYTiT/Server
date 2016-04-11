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

	def notify_requesters_of_response(vc)
		requesters_ids = "SELECT user_id FROM moment_request_users WHERE request_id = #{self.id}"
		requesters = User.where("id IN (#{requesters_ids})") 
=begin
		for requester in requesters
			if requester != nil
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
=end
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

end