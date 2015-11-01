class FeedActivity < ActiveRecord::Base
	belongs_to :feed
	belongs_to :user
	belongs_to :venue

	belongs_to :venue_comment
	belongs_to :feed_venue
	belongs_to :feed_user
	belongs_to :feed_topic
	belongs_to :feed_share

	belongs_to :feed_recommendation

	has_many :likes, :dependent => :destroy
	has_many :feed_activity_comments, :dependent => :destroy

	def self.implicit_topic_activity_find(u_id, f_id, topic_message)
		type = "premature new topic: #{topic_message.first(50)}..."
		lookup = FeedActivity.where("user_id = ? AND feed_id = ? AND activity_type = ? AND created_at > ?", u_id, f_id, type, Time.now-10.minutes).order("created_at DESC").first
		if lookup == nil
			fa = FeedActivity.create!(:feed_id => f_id, :user_id => u_id, :activity_type => type, :adjusted_sort_position => nil)
			return fa
		else
			return lookup
		end		
	end

	def self.implicit_topic_activity_create(f_t_id, u_id, f_id, topic_message)
		type = "premature new topic: #{topic_message.first(50)}..."
		lookup = FeedActivity.where("user_id = ? AND feed_id = ? AND activity_type = ? AND created_at > ?", u_id, f_id, type, Time.now-10.minutes).order("created_at DESC").first
		if lookup != nil
			lookup.update_columns(feed_topic_id: f_t_id)
			lookup.update_columns(activity_type: "new topic")
		else
			FeedActivity.create!(:feed_topic_id => f_t_id, :feed_id => f_id, :user_id => u_id, :activity_type => "new topic", :adjusted_sort_position => Time.now.to_i)
		end
	end

	def did_like?(user) 
		if like_id == nil
			nil
		else
			like.user == user
		end
	end

	def update_comment_parameters(t, u_id)
		increment!(:num_comments, 1)
		update_columns(latest_comment_time: t)
		if FeedActivityComment.where("user_id = ? AND feed_activity_id = ?", u_id, self.id).count == 1
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

	

end
