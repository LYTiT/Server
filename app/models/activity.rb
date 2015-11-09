class Activity < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue

	belongs_to :feed

	belongs_to :venue_comment
	belongs_to :feed_venue
	belongs_to :feed_user


	belongs_to :feed_recommendation

	has_many :likes, :dependent => :destroy
	has_many :activity_comments, :dependent => :destroy
	has_many :activity_feeds, :dependent => :destroy
	has_many :feeds, through: :activity_feeds


	def liked_by?(user) 
		self.likes.where("liker_id = ?", user.id).any?
	end

	def update_comment_parameters(t, u_id)
		increment!(:num_comments, 1)
		update_columns(latest_comment_time: t)
		if ActivityComment.where("user_id = ? AND activity_id = ?", u_id, self.id).count == 1
			self.increment!(:num_participants, 1)
		end
	end

	def implicit_created_at
		if venue_comment != nil
			venue_comment.time_wrapper
		else
			created_at
		end
	end

	def implicit_action_user
		if feed_venue != nil
			feed_venue.user
		elsif like != nil
			like.liker
		elsif feed_user != nil
			feed_user.user
		else
			nil
		end
	end

	def underlying_user
		if activity_type == "added venue"
			return feed_venue.user	
		elsif activity_type == "new member" 
			return feed_user.user
		elsif activity_type == "liked message" || activity_type == "liked added venue"
			return like.liker
		elsif activity_type == "new topic"
			return feed_topic.user
		else
			return	nil
		end
	end

#Feed Shares--------->
	def self.new_list_share(instagram_details, vc_id, u_id, f_ids, comment)
		if vc_id == nil
			vc = VenueComment.convert_instagram_details_to_vc(instagram_details)
		else
			vc = VenueComment.find_by_id(vc_id)
		end

		fa = Activity.create!(:activity_type => "shared moment", :user_id => u_id, :venue_comment_id => vc.id, :venue_id => vc.venue_id, :adjusted_sort_position => Time.now.to_i, :feed_id => f_ids.first, :num_lists => f_ids.count)
		if comment != nil && comment != ""
			fac = ActivityComment.create!(:activity_id => fa.id, :user_id => u_id, :comment => comment)
			fa.update_comment_parameters(Time.now, u_id)
		end	

		f_ids.each{|f_id| ActivityFeed.create!(:activity_id => fa.id, :feed_id => f_id)}

		fa.new_feed_share_notification(f_ids)
	end

	def new_feed_share_notification(f_ids)
		feed_users = FeedUser.where("feed_id IN (?)", f_ids).includes(:user)
		
		for feed_user in feed_users
			notification_type = "feed_share/#{self.id}"
			notification_check = (Notification.where(user_id: feed_user.id, message: notification_type).count == 0)
			if feed_user.is_subscribed == true && (feed_user.user_id != self.user_id && feed_user.user != nil) && (notification_check == true)
				self.send_new_feed_share_notification(feed_user.user, feed_user.feed)
			end
		end
	end

	def send_new_feed_share_notification(member, activity_feed_of_member)
		payload = {
		    :object_id => self.id, 
		    :activity_id => self.id,
		    :type => 'share_notification',
		    :num_likes => num_likes,
  			:has_liked => self.liked_by?(member),

  			:num_chat_participants => num_participants,
  			:latest_chat_time => latest_comment_time,

		    :user_id => user_id,
		    :user_name => user.name,
		    :user_phone => user.phone_number,

		    :feed_id => activity_feed_of_member.id,
		    :feed_name => activity_feed_of_member.name,
		    :feed_color => activity_feed_of_member.feed_color,

		    :num_activity_lists => num_lists,

		    :media_type => venue_comment.try(:media_type),
		    :image_url_1 => venue_comment.try(:image_url_1),
		    :image_url_2 => venue_comment.try(:image_url_2),
		    :image_url_3 => venue_comment.try(:image_url_3),
		    :video_url_1 => venue_comment.try(:video_url_1),
		    :video_url_2 => venue_comment.try(:video_url_2),
		    :video_url_3 => venue_comment.try(:video_url_3),
		    :venue_id => venue_id,
  			:venue_name => venue.try(:name),
  			:city => venue.try(:city),
  			:country => venue.try(:country),
		  	:latitude => venue.try(:latitude),
  			:longitude => venue.try(:longitude),
  			:color_rating => venue.try(:color_rating),
  			:instagram_location_id => venue.try(:instagram_location_id)		    
		}


		type = "feed_share/#{self.id}"

		notification = self.store_new_shared_venue_comment_notification(payload, member, type)
		payload[:notification_id] = notification.id

		#underlying_feed_ids = "SELECT feed_id FROM activity_feeds WHERE activity_id = #{self.id}"
		#member_activity_feed_memberships = member.feed_users.where("feed_id IN (#{underlying_feed_ids})")

		if num_lists == 1
			preview = "#{user.name} shared a Moment with #{activity_feed_of_member.name}"
		else
			preview = "#{user.name} shared a Moment with #{activity_feed_of_member.name} & others"
		end
		
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
		  :response => nil,
		  :user_id => member.id,
		  :read => false,
		  :message => type,
		  :deleted => false
		}
		Notification.create(notification)
	end



#Feed Topics--------->
	def self.new_list_topic(u_id, topic_message, f_ids)
		new_activity = Activity.create!(:user_id => u_id, :activity_type => "new topic", :adjusted_sort_position => Time.now.to_i, :message => topic_message, :feed_id => f_ids.first, :num_lists => f_ids.count)
		ActivityFeed.delay.bulk_creation(new_activity.id, f_ids)
		new_activity.new_topic_notification(f_ids)
		return new_activity
	end

	def new_topic_notification(f_ids)
		feed_users = FeedUser.where("feed_id IN (?)", f_ids).includes(:user)
		for feed_user in feed_users
			notification_type = "feed_topic/#{self.id}"
			notification_check = (Notification.where(user_id: feed_user.id, message: notification_type).count == 0)
			if feed_user.is_subscribed == true && (feed_user.user_id != self.user_id && feed_user.user != nil) && (notification_check == true)
				self.delay.send_new_topic_notification(feed_user.user, feed_user.feed)
			end
		end
	end

	def send_new_topic_notification(member, activity_feed_of_member)
		payload = {
		    :object_id => self.id, 
		    :activity_id => self.id,
		    :type => 'new_topic_notification',
		    :num_likes => num_likes,
  			:has_liked => self.liked_by?(member),

  			:num_chat_participants => num_participants,
  			:latest_chat_time => latest_comment_time,

			:user_id => user_id,
		    :user_name => user.name,
		    :user_phone => user.phone_number,
		    :feed_id => activity_feed_of_member.id,
		    :feed_name => activity_feed_of_member.name,
		    :feed_color => activity_feed_of_member.feed_color,
		    :num_activity_lists => num_lists,
		    :topic => self.message
		}


		type = "feed_topic/#{self.id}"

		notification = self.store_new_topic_notification(payload, member, type)
		payload[:notification_id] = notification.id

		#underlying_feed_ids = "SELECT feed_id FROM activity_feeds WHERE activity_id = #{self.id}"
		#member_activity_feed_memberships = member.feed_users.where("feed_id IN (#{underlying_feed_ids})")

		if num_lists == 1
			preview = "#{user.name} opened a new topic in #{activity_feed_of_member.name}"
		else
			preview = "#{user.name} opened a new topic in #{activity_feed_of_member.name} & others"
		end

		if member.push_token
		  count = Notification.where(user_id: member.id, read: false, deleted: false).count
		  APNS.send_notification(member.push_token, { :priority =>10, :alert => preview, :content_available => 1, :other => payload, :badge => count})
		end

	end

	def store_new_topic_notification(payload, member, type)
		notification = {
		  :payload => payload,
		  :gcm => user.gcm_token.present?,
		  :apns => user.push_token.present?,
		  :response => nil,
		  :user_id => member.id,
		  :read => false,
		  :message => type,
		  :deleted => false
		}
		Notification.create(notification)
	end

end
