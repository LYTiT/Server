class Api::V1::FeedsController < ApiBaseController
	skip_before_filter :set_user, only: [:create]

	def create
		feed = Feed.new(:name => params[:name], :user_id => params[:user_id], :latest_viewed_time => Time.now, :feed_color => params[:feed_color], :open => params[:open], :description => params[:list_description])
		feed.save

		feed_user = FeedUser.new(:feed_id => feed.id, :user_id => params[:user_id], :creator => true)
		feed_user.save

		render json: feed.as_json
	end

	def delete
		feed = Feed.find_by_id(params[:id])
		feed.destroy

		render json: { success: true }
	end

	def edit_feed
		feed = Feed.find_by_id(params[:id])
		if feed 
			if params[:name] != nil
				feed.update_columns(name: params[:name])
			end

			if params[:open] != nil
				feed.update_columns(open: params[:open])
			end

			if params[:list_description] != nil
				feed.update_columns(description: params[:list_description])
			end

			if params[:feed_color] != nil
				feed.update_columns(feed_color: params[:feed_color])
			end

			render json: feed.as_json
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['No List found'] } }, status: :unprocessable_entity
		end
	end

	def edit_subscription
		feed_user = FeedUser.where("user_id = ? AND feed_id = ?", params[:user_id], params[:feed_id]).first
		if feed_user != nil
			feed_user.update_columns(is_subscribed: params[:subscribed])
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['No such list user'] } }, status: :unprocessable_entity
		end
	end

	def search
		@user = User.find_by_id(params[:user_id])
		@feeds = Feed.search(params[:q]).includes(:feed_users).limit(15)
	end

	def add_feed
		feed = Feed.find_by_id(params[:feed_id])
		feed.calibrate_num_members
		
		feed_user = FeedUser.new(:feed_id => feed.id, :user_id => params[:user_id], :creator => false)
		if feed_user.save
			feed.increment!(:num_users, 1)	
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['User could not add feed'] } }, status: :unprocessable_entity
		end
	end

	def leave_feed
		feed = Feed.find_by_id(params[:feed_id])
		feed.decrement!(:num_users, 1)

		feed_user = FeedUser.where("user_id = ? AND feed_id = ?", params[:user_id], params[:feed_id]).first
		feed_user.destroy
		render json: { success: true }
	end

	def get_members
		@feed = Feed.find_by_id(params[:id])
		@users = @feed.users
	end

	def get_venues
		@user = User.where("id = ?", params[:user_id]).includes(:likes).first
		@feed = Feed.find_by_id(params[:id])
		@venues = @feed.venues.includes(:feed_venues, :activities)
	end

	def add_venue
		if FeedVenue.where("feed_id = ? AND venue_id = ?", params[:id], params[:venue_id]).any? == false
			new_feed_venue = FeedVenue.new(:feed_id => params[:id], :venue_id => params[:venue_id], :user_id => params[:user_id], :description => params[:added_note])
			if new_feed_venue.save
				new_feed_venue.feed.increment!(:num_venues, 1)
				render json: { success: true }
			end
		else
			render json: { success: false }
		end
	end

	#Adding a venue by name.
	def add_raw_venue
		if params[:country] != nil
			venue = Venue.fetch(params[:name], params[:formatted_address], params[:city], params[:state], params[:country], params[:postal_code], params[:phone_number], params[:latitude], params[:longitude])
		else		
			venue = Venue.fetch_venues_for_instagram_pull(params[:name], params[:latitude], params[:longitude], params[:instagram_location_id])
		end

		if FeedVenue.where("feed_id = ? AND venue_id = ?", params[:feed_id], venue.id).any? == false
			new_feed_venue = FeedVenue.new(:feed_id => params[:feed_id], :venue_id => venue.id, :user_id => params[:user_id], :description => params[:added_note])
			if new_feed_venue.save
				feed = Feed.find_by_id(params[:feed_id])
				feed.increment!(:num_venues, 1)
				render json: { id: venue.id }
			end
		else
			render json: { success: false }
		end
	end

	def edit_venue_description
		fv = FeedVenue.find_by_id(params[:feed_venue_id])
		fv.description = params[:description]
		if fv.save
			render json: { success: false }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Could edit feed venue description'] } }, status: :unprocessable_entity
		end
	end

	def remove_venue
		feed_venue = FeedVenue.where("feed_id = ? AND venue_id = ?", params[:id], params[:venue_id]).first
		feed_venue.destroy
		Feed.find_by_id(params[:id]).decrement!(:num_venues, 1)
		render json: { success: true }
	end

	def register_open
		feed = Feed.find_by_id(params[:feed_id])			
		feed.update_columns(latest_viewed_time: Time.now)
		feed.update_columns(new_media_present: false)
		#feed.update_media	
		render json: { success: true }
	end

	def get_feed
		@user = User.find_by_authentication_token(params[:auth_token])
		@feed = Feed.find_by_id(params[:feed_id])
	end

	def get_activity
		@user = User.find_by_authentication_token(params[:auth_token])
		@feed = Feed.find_by_id(params[:feed_id])
		@activities = @feed.activity_of_the_day.page(params[:page]).per(10)
	end

	def get_activity_object
		@user = User.find_by_id(params[:user_id])
		@activity = Activity.find_by_id(params[:activity_id])
	end

	def get_activity_lists
		@activity = Activity.find_by_id(params[:activity_id])
		@lists = @activity.feeds
	end

	def get_likers
		fa = Activity.find_by_id(params[:activity_id])
		liker_ids = "SELECT liker_id FROM likes WHERE activity_id = #{fa.id}"
		@likers = User.where("id IN (#{liker_ids})").page(params[:page]).per(10)
	end

	def add_new_topic_to_feed
		feed_ids = params[:feed_ids].split(',').map(&:to_i)
		new_topic = Activity.new_list_topic(params[:user_id], params[:topic], feed_ids)
		render json: { success: true }
	end

	def share_with_feed
		feed_ids = params[:feed_ids].split(',').map(&:to_i)
		Activity.delay.new_list_share(params[:venue_comment_details], params[:venue_comment_id], params[:user_id], feed_ids, params[:comment])
		render json: { success: true }
	end

	def like_activity
		@user = User.find_by_authentication_token(params[:auth_token])
		if params[:activity_id] != nil
			fa = Activity.find_by_id(params[:activity_id])
		else
			fa = Activity.implicit_topic_activity_find(params[:user_id], params[:feed_id], params[:topic])
		end
		fa.increment!(:num_likes, 1)
		if Like.create!(:liker_id => params[:user_id], :liked_id => fa.user_id, :activity_id => fa.id)
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Could not like feed activity'] } }, status: :unprocessable_entity
		end
	end

	def unlike_activity
		if params[:activity_id] != nil
			fa = Activity.find_by_id(params[:activity_id])
		else
			fa = Activity.implicit_topic_activity_find(params[:user_id], params[:feed_id], params[:topic])
		end
		if Like.where("liker_id = ? AND activity_id = ?", params[:user_id], params[:activity_id]).first.try(:delete)
			fa.decrement!(:num_likes, 1)
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Could not unlike feed activity'] } }, status: :unprocessable_entity
		end
	end

	def add_activity_comment
		fac = ActivityComment.create!(:activity_id => params[:activity_id], :user_id => params[:user_id], :comment => params[:comment])
		if fac
			if params[:activity_id] != nil
				fa = Activity.find_by_id(params[:activity_id])
			else
				fa = Activity.implicit_topic_activity_find(params[:user_id], params[:feed_id], params[:topic])
			end
			fa.update_comment_parameters(Time.now, params[:user_id])
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Could not create activity comment'] } }, status: :unprocessable_entity
		end
	end

	def get_activity_comments
		@activity_comments = Activity.find_by_id(params[:activity_id]).activity_comments.includes(:user).order("id DESC").page(params[:page]).per(10)
	end

	def get_venue_comments
		feed = Feed.find_by_id(params[:feed_id])
		@comments = feed.comments.page(params[:page]).per(10)
	end

	def meta_search
		@results = Feed.meta_search(params[:q])
	end

	def get_categories
		@categories = Feed.categories
	end

	def get_spotlyts
		@user = User.find_by_authentication_token(params[:auth_token])
		@spotlyts = FeedRecommendation.where("spotlyt IS TRUE").includes(:feed)
	end

	def get_initial_recommendations
		categories_array = params[:categories].split(',') rescue nil
		if categories_array != nil
			@recommendations = FeedRecommendation.where("category IN (?) AND active IS TRUE", categories_array).includes(:feed)
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Categories are NIL'] } }, status: :unprocessable_entity
		end		
	end
	
	def get_recommendations
		feed_ids = "SELECT feed_id from feed_recommendations WHERE active IS TRUE AND spotlyt IS FALSE"
		@recommendations = Feed.where("id IN (#{feed_ids})")
	end

	def invite_user
		fi = FeedInvitation.create!(:inviter_id => params[:inviter_id], :invitee_id => params[:invitee_id], :feed_id => params[:feed_id])
		if fi != nil
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Could not create invitation'] } }, status: :unprocessable_entity
		end
	end

end