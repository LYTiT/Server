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
		if self.activity_type == "added_venue"
			self.feed_venue.increment!(:num_comments, 1)
		end

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
		if activity_type == "added_venue"
			return feed_venue.user	
		elsif activity_type == "new_member" 
			return feed_user.user
		elsif activity_type == "liked message" || activity_type == "liked added_venue"
			return like.liker
		elsif activity_type == "new_topic"
			return feed_topic.user
		else
			return	nil
		end
	end

#Feed Shares--------->
	def self.new_list_share(vc_details, vc_id, origin_venue_id, u_id, f_ids, comment)
		if vc_id == nil
			if vc_details["instagram_id"] != nil
				vc = VenueComment.convert_raw_instagram_params_to_vc(vc_details, origin_venue_id)
			else
				tweet = Tweet.convert_raw_tweet_params(vc_details, origin_venue_id)
				vc = VenueComment.where("tweet ->> 'id' = '#{tweet.id}'").first
			end	
		else
			vc = VenueComment.find_by_id(vc_id)
		end

		if vc != nil
			user = User.find_by_id(u_id)
			feed = Feed.find_by_id(f_ids.first)
			new_activity = Activity.create!(:activity_type => "shared_#{vc.entry_type}", :feed_id => f_ids.first, :feed_details => feed.partial, :num_lists => f_ids.count,
			 :user_id => user.id, :user_details => user.partial, :venue_details => vc.venue_details, :venue_comment_id => vc.id, :venue_comment_details => vc.to_json, 
			 :adjusted_sort_position => Time.now.to_i)								
			
			if comment != nil && comment != ""
				fac = ActivityComment.create!(:activity_id => new_activity.id, :user_id => u_id, :user_details => user.partial, :comment => comment)
				new_activity.update_comment_parameters(Time.now, u_id)
			end	

			ActivityFeed.bulk_creation(new_activity.id, f_ids)
			new_activity.delay(:priority => -3).new_feed_share_notification(f_ids)

			return new_activity
		else
			puts "No underlying venue comment to share"
		end
	end

	def new_feed_share_notification(f_ids)
		feed_users = FeedUser.where("feed_id IN (?)", f_ids).includes(:user, :feed)
		
		for feed_user in feed_users
			notification_type = "feed_share/#{self.id}"
			notification_check = (Notification.where(user_id: feed_user.user_id, message: notification_type).count == 0)
			if feed_user.is_subscribed == true && (feed_user.user_id != self.user_id && feed_user.user != nil) && (notification_check == true)
				self.send_new_feed_share_notification(feed_user.user, feed_user.feed)
			end
		end
	end

	def send_new_feed_share_notification(member, activity_feed_of_member)
		if self.venue_comment_details["entry_type"] == "instagram"
			media_type = self.venue_comment_details["instagram"]["media_type"]
		elsif self.venue_comment_details["entry_type"] == "lytit_post"
			media_type = self.venue_comment.venue_comment_details["lytit_post"]["media_type"] 
		else
			media_type = nil
		end

		if self.venue_comment_details["entry_type"] == "tweet"
			content_origin = "twitter"
		else
			content_origin = self.venue_comment_details["entry_type"]
		end
			
		payload = {
			:intended_for => member.id,
		    :object_id => self.id, 
		    :activity_id => self.id,
		    :venue_comment_id => self.venue_comment_id,
		    :type => 'share_notification',
		    :num_likes => num_likes,
  			:has_liked => self.liked_by?(member),

  			:num_chat_participants => num_participants,
  			:latest_chat_time => latest_comment_time.to_i,

		    :user_id => user_id,
		    :user_name => user.name,
		    :user_phone => user.phone_number,
		    :fb_id => user.facebook_id,
      		:fb_name => user.facebook_name,

      		:content_origin => content_origin,
      		:media_type => media_type,

		    :feed_id => activity_feed_of_member.id,
		    :feed_name => activity_feed_of_member.name,
		    :feed_color => activity_feed_of_member.feed_color,

		    :num_activity_lists => num_lists		    	
		}


		type = "feed_share/#{self.id}"

		notification = self.store_new_shared_venue_comment_notification(payload, member, type)
		payload[:notification_id] = notification.id

		#underlying_feed_ids = "SELECT feed_id FROM activity_feeds WHERE activity_id = #{self.id}"
		#member_activity_feed_memberships = member.feed_users.where("feed_id IN (#{underlying_feed_ids})")

		if num_lists == 1
			preview = "#{user.name} shared a moment with #{activity_feed_of_member.name}"
		else
			preview = "#{user.name} shared a moment with #{activity_feed_of_member.name} & others"
		end
		
		if member.push_token && member.active == true
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
		feed = Feed.find_by_id(f_ids.first)
		user = User.find_by_id(u_id)

		new_activity = Activity.create!(:activity_type => "new_topic", :feed_id => feed.id, :feed_details => feed.partial, :user_id => user.id, :user_details => user.partial,
			:topic_details => {:message => topic_message}, :adjusted_sort_position => Time.now.to_i)

=begin
		new_activity = Activity.create!(:user_id => u_id, :user_name => user.name, :user_phone => user.phone_number, :user_facebook_id => user.facebook_id, 
			:user_facebook_name => user.facebook_name, :activity_type => "new_topic", :adjusted_sort_position => Time.now.to_i, :message => topic_message, 
			:feed_id => f_ids.first, :feed_name => feed.name, :feed_color => feed.feed_color, :num_lists => f_ids.count)
=end			

		ActivityFeed.bulk_creation(new_activity.id, f_ids)
		feed_ids = "SELECT feed_id FROM activity_feeds WHERE activity_id = #{new_activity.id}"
		u_ids = FeedUser.where("feed_id IN (#{feed_ids})").pluck(:user_id)
		User.purge_cached_news_feed(u_ids)
		new_activity.delay(:priority => -4).new_topic_notification(f_ids)
		return new_activity
	end

	def new_topic_notification(f_ids)
		feed_users = FeedUser.where("feed_id IN (?)", f_ids).includes(:user, :feed)
		for feed_user in feed_users
			notification_type = "feed_topic/#{self.id}"
			notification_check = (Notification.where(user_id: feed_user.user_id, message: notification_type).count == 0)
			if feed_user.is_subscribed == true && (feed_user.user_id != self.user_id && feed_user.user != nil) && (notification_check == true)
				self.send_new_topic_notification(feed_user.user, feed_user.feed)
			end
		end
	end

	def send_new_topic_notification(member, activity_feed_of_member)
		payload = {
			:intended_for => member.id,
		    :object_id => self.id, 
		    :activity_id => self.id,
		    :type => 'new_topic_notification',
		    :num_likes => num_likes,
  			:has_liked => self.liked_by?(member),

  			:num_chat_participants => num_participants,
  			:latest_chat_time => latest_comment_time.to_i,

			:user_id => user_id,
		    :user_name => user.name,
		    :user_phone => user.phone_number,
		    :fb_id => user.facebook_id,
		    :fb_name => user.facebook_name,
		    :feed_id => activity_feed_of_member.id,
		    :feed_name => activity_feed_of_member.name,
		    :feed_color => activity_feed_of_member.feed_color,
		    :num_activity_lists => num_lists,
		    :topic => self.topic_details["message"]
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

		if member.push_token && member.active == true
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

	def Activity.select_content_for_featured_venue_activity(featured_venue_entry, user_id, feed_id, feed_name, feed_color)
		roll = rand(9)
		if roll < 6
			content = {:id => featured_venue_entry["venue_comment_id"], :media_type => featured_venue_entry["media_type"], :venue_id => featured_venue_entry["id"],
				:time_wrapper => featured_venue_entry["venue_comment_created_at"].to_datetime, :content_origin => featured_venue_entry["venue_comment_content_origin"],
				:instagram_id => featured_venue_entry["venue_comment_instagram_id"], :thirdparty_username => featured_venue_entry["venue_comment_thirdparty_username"],
				:instagram_user_id => featured_venue_entry["venue_comment_instagram_user_id"], :image_url_1 => featured_venue_entry["image_url_1"], 
				:image_url_2 => featured_venue_entry["image_url_2"], :image_url_3 => featured_venue_entry["image_url_3"], :video_url_1 => featured_venue_entry["video_url_1"], 
				:video_url_2 => featured_venue_entry["video_url_2"], :video_url_3 => featured_venue_entry["video_url_3"]}
		else
			if featured_venue_entry["lytit_tweet_id"] != nil and featured_venue_entry["tweet_created_at"].to_datetime >= (Time.now - 2.hour)
				if featured_venue_entry["image_url_1"][0..9] == "http://pbs"
					image_url_1 = featured_venue_entry["image_url_1"]
					image_url_2 = featured_venue_entry["image_url_2"]
					image_url_3 = featured_venue_entry["image_url_3"]
				else
					image_url_1 = nil
					image_url_2 = nil
					image_url_3 = nil
				end

				content = {:id => featured_venue_entry["lytit_tweet_id"], :twitter_id => featured_venue_entry["twitter_id"], :tweet_text => featured_venue_entry["tweet_text"],
					:author_id => featured_venue_entry["tweet_author_id"], :author_name => featured_venue_entry["tweet_author_name"],
					:author_avatar => featured_venue_entry["tweet_author_avatar_url"], :timestamp => featured_venue_entry["tweet_created_at"].to_datetime, :venue_id => featured_venue_entry["id"],
					:handle => featured_venue_entry["tweet_handle"], :image_url_1 => image_url_1, :image_url_2 => image_url_2,
					:image_url_3 => image_url_3}
			else
				content = {:id => featured_venue_entry["venue_comment_id"], :media_type => featured_venue_entry["media_type"], :venue_id => featured_venue_entry["id"],
					:time_wrapper =>  featured_venue_entry["venue_comment_created_at"].to_datetime, :content_origin => featured_venue_entry["venue_comment_content_origin"],
					:instagram_id => featured_venue_entry["venue_comment_instagram_id"], :thirdparty_username => featured_venue_entry["venue_comment_thirdparty_username"],
					:instagram_user_id => featured_venue_entry["venue_comment_instagram_user_id"], :image_url_1 => featured_venue_entry["image_url_1"], 
					:image_url_2 => featured_venue_entry["image_url_2"], :image_url_3 => featured_venue_entry["image_url_3"], :video_url_1 => featured_venue_entry["video_url_1"], 
					:video_url_2 => featured_venue_entry["video_url_2"], :video_url_3 => featured_venue_entry["video_url_3"]}		
			end
		end
		if content.first.nil? == false && feed_id != nil
			Activity.delay(:priority => -3).create_featured_list_venue_activity(featured_venue_entry, content, user_id, feed_id, feed_name, feed_color)
		end
		return content		
	end

	def Activity.create_featured_list_venue_activity(featured_venue_entry, content, user_id, feed_id, feed_name, feed_color)		
		if featured_venue_entry != nil			
			if feed_id == nil
				if featured_venue_entry.class.name == "Venue"
					venue_id = featured_venue_entry.id
				else
					venue_id = featured_venue_entry["id"]
				end

				feed = Feed.joins(:feed_venues, :feed_users).where("feed_venues.venue_id = ? AND feed_users.user_id = ?", venue_id, user_id).order("feed_users.interest_score DESC").first
				if feed != nil				
					feed_id = feed.id
					feed_name = feed.name
					feed_color = feed.feed_color
				else
					return nil
				end
			end

			if ((content[:twitter_id] == nil) && Activity.where("feed_id = ? AND activity_type = ? AND venue_comment_id = ?", feed_id, "featured_list_venue", content[:id]).any? == false) || ((content[:twitter_id] != nil) && Activity.where("feed_id = ? AND activity_type = ? AND lytit_tweet_id = ?", feed_id, "featured_list_venue", content[:id]).any? == false)
			#if Activity.where("feed_id = ? AND activity_type = ? AND (venue_comment_id = ? OR lytit_tweet_id = ?)", feed_id, "featured_list_venue", content.id, content.id).any? == false
				if featured_venue_entry.class.name == "Venue"
					venue_id = featured_venue_entry.id
					venue_name = featured_venue_entry.name
					venue_address = featured_venue_entry.address
					venue_city = featured_venue_entry.city
					venue_country = featured_venue_entry.country
					venue_latitude = featured_venue_entry.latitude
					venue_longitude = featured_venue_entry.longitude
					venue_instagram_location_id = featured_venue_entry.instagram_location_id
				else
					venue_id = featured_venue_entry["id"]
					venue_name = featured_venue_entry["name"]
					venue_address = featured_venue_entry["address"]
					venue_city = featured_venue_entry["city"]
					venue_country = featured_venue_entry["country"]
					venue_latitude = featured_venue_entry["latitude"]
					venue_longitude = featured_venue_entry["longitude"]
					venue_instagram_location_id = featured_venue_entry["instagram_location_id"]
				end

				new_activity = nil

				if content.class.name == "VenueComment"
					new_activity = Activity.create!(:feed_id => feed_id, :feed_name => feed_name,
						:feed_color => feed_color, :activity_type => "featured_list_venue",
						:tag_1 => featured_venue_entry["tag_1"], 
						:tag_2 => featured_venue_entry["tag_2"], 
						:tag_3 => featured_venue_entry["tag_3"],
						:tag_4 => featured_venue_entry["tag_4"], 
						:tag_5 => featured_venue_entry["tag_5"], 
						:venue_id => venue_id, :venue_name => venue_name,
						:venue_address => venue_address, :venue_city => venue_city,
						:venue_country => venue_country, :venue_latitude => venue_latitude, 
						:venue_longitude => venue_longitude, :venue_instagram_location_id => venue_instagram_location_id,
						:venue_comment_id => content[:id], :venue_comment_created_at => content[:time_wrapper],
						:media_type => content[:media_type], :image_url_1 => content[:image_url_1], :image_url_2 => content[:image_url_2],
						:image_url_3 => content[:image_url_3], :video_url_1 => content[:video_url_1], :video_url_2 => content[:video_url_2],
						:video_url_3 => content[:video_url_3], :venue_comment_content_origin => content[:content_origin],
						:venue_comment_thirdparty_username => content[:thirdparty_username], :adjusted_sort_position => content[:time_wrapper].to_i)
				else
					new_activity = Activity.create!(:feed_id => feed_id, :feed_name => feed_name,
						:feed_color => feed_color, :activity_type => "featured_list_venue",
						:tag_1 => featured_venue_entry["tag_1"], 
						:tag_2 => featured_venue_entry["tag_2"], 
						:tag_3 => featured_venue_entry["tag_3"],
						:tag_4 => featured_venue_entry["tag_4"], 
						:tag_5 => featured_venue_entry["tag_5"], 
						:venue_id => venue_id, :venue_name => venue_name,
						:venue_address => venue_address, :venue_city => venue_city,
						:venue_country => venue_country, :venue_latitude => venue_latitude, 
						:venue_longitude => venue_longitude, :venue_instagram_location_id => venue_instagram_location_id,						
						:image_url_1 => content[:image_url_1], :image_url_2 => content[:image_url_2],
						:image_url_3 => content[:image_url_3], :lytit_tweet_id => content[:id], :twitter_id => content[:twitter_id], 
						:tweet_text => content[:tweet_text], :tweet_created_at => content[:timestamp],
						:tweet_author_name => content[:author_name], :tweet_author_id => content[:author_id],
						:tweet_author_avatar_url => content[:author_avatar], :tweet_handle => content[:handle], 
						:adjusted_sort_position => content[:timestamp].to_i)
				end

				if new_activity != nil
					ActivityFeed.create!(:feed_id => feed_id, :activity_id => new_activity.id)
				end
			else
				puts "Attempted dupe activity creation"
			end
		else
			puts "Nil activity encountered"
		end
	end

	def Activity.feature_venue_cleanup
		expired_featured_venue_activity_ids = "SELECT id FROM activities WHERE (activity_type = 'featured_list_venue' AND (NOW() - created_at) > INTERVAL '1 HOUR')"
    	ActivityFeed.where("activity_id IN (#{expired_featured_venue_activity_ids})").delete_all
    	Activity.where("id IN (#{expired_featured_venue_activity_ids})").delete_all
	end

end
