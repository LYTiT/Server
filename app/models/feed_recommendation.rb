class FeedRecommendation < ActiveRecord::Base
	belongs_to :feed

	has_one :activity, :dependent => :destroy


	def FeedRecommendation.for_user(user, user_lat, user_long)
		user_feed_ids = "SELECT feed_id FROM feed_users WHERE user_id = #{user.id}"

		v_weight = 0.5
		m_weight = 0.1
		recommendations = Feed.where("id NOT IN (#{user_feed_ids}) AND num_venues > 0").order("(num_venues*#{v_weight}+num_users*#{m_weight})/(ACOS(least(1,COS(RADIANS(#{user_lat}))*COS(RADIANS(#{user_long}))*COS(RADIANS(feeds.central_mass_latitude))*COS(RADIANS(feeds.central_mass_longitude))+COS(RADIANS(#{user_lat}))*SIN(RADIANS(#{user_long}))*COS(RADIANS(feeds.central_mass_latitude))*SIN(RADIANS(feeds.central_mass_longitude))+SIN(RADIANS(#{user_lat}))*SIN(RADIANS(feeds.central_mass_latitude))))*6376.77271) DESC").limit(50).order("RANDOM()")
	end

	def FeedRecommendation.for_categories(categories, user_lat, user_long)
		#categories are a string and have to be of format: " 'parks', 'dogs' " (Note the single quotation marks around each individual category)
		feed_recommendation_ids = "SELECT feed_id FROM feed_recommendations WHERE category IN (#{categories})"
		v_weight = 0.5
		m_weight = 0.1
		recommendations = Feed.where("id IN (#{feed_recommendation_ids})").order("(num_venues*#{v_weight}+num_users*#{m_weight})/(ACOS(least(1,COS(RADIANS(#{user_lat}))*COS(RADIANS(#{user_long}))*COS(RADIANS(feeds.central_mass_latitude))*COS(RADIANS(feeds.central_mass_longitude))+COS(RADIANS(#{user_lat}))*SIN(RADIANS(#{user_long}))*COS(RADIANS(feeds.central_mass_latitude))*SIN(RADIANS(feeds.central_mass_longitude))+SIN(RADIANS(#{user_lat}))*SIN(RADIANS(feeds.central_mass_latitude))))*6376.77271) DESC").limit(50).order("RANDOM()")
	end

	def create_feed_acitivity
		Activity.create!(:feed_id => feed_id, :activity_type => "made spotlyt", :feed_recommendation_id => self.id, :adjusted_sort_position => (self.created_at).to_i)
	end

	def set_image_url
		last_venue_comment_url = self.feed.latest_image_thumbnail_url
		self.update_columns(image_url: last_venue_comment_url)
	end

	def spotlyt_notification
		begin
			if (FeedUser.where("feed_id = ? AND user_id =?", feed.id, feed.user.id).first.is_subscribed == true && feed.user.id != self.user.id) && spotlyt == true
				self.delay.send_spotlyt_notification
			end
		rescue
			puts "List has no admin"
		end
	end

	def send_spotlyt_notification
		payload = {
		    :object_id => self.id, 
		    :type => 'made_spotlyt_notification', 
		    :user_id => user.id,
		    :user_name => user.name,
		    :feed_id => feed.id,
		    :feed_name => feed.name

		}

		alert = "Congratulations! Your #{feed.name} List is in the Spotlyt!"

		notification = self.store_new_user_notification(payload, feed.user, "made spotlyt")
		payload[:notification_id] = notification.id

		if feed.user.push_token && feed.user.push_token == true
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

	def FeedRecommendation.set_daily_spotlyt
		previous_spotlyt_ids = "SELECT feed_id FROM feed_recommendations WHERE spotlyt IS TRUE"

		v_weight = 0.5
		m_weight = 0.1
		new_spotlyt_ids = Feed.where("num_venues > 5 AND num_users > 0 AND id NOT IN (#{previous_spotlyt_ids})").order("(num_venues*#{v_weight}+num_users*#{m_weight})").limit(30).pluck(:id).shuffle[0..2]

		FeedRecommendation.update_all(spotlyt: false)
		for id in new_spotlyt_ids
			feed_rec = FeedRecommendation.where("feed_id = ?", id).first
			if  feed_rec == nil
				FeedRecommendation.create!(:feed_id => id, :active => true, :spotlyt => true)
			else
				feed_rec.update_columns(spotlyt: true)
			end
		end		
	end

end