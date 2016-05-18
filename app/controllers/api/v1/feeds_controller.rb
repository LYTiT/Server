class Api::V1::FeedsController < ApiBaseController
	skip_before_filter :set_user, only: [:create]

	def create
		is_open = params[:open] || true
		is_private = params[:is_private] || true
		feed = Feed.create!(:name => params[:name].strip, :user_id => params[:user_id], :feed_color => params[:feed_color], :open => is_open, :description => params[:list_description], :preview_image_url => params[:preview_image_url], :cover_image_url => params[:cover_image_url], :is_private => is_private)

		feed_user = FeedUser.create!(:feed_id => feed.id, :user_id => params[:user_id], :creator => true, :interest_score => 1.0)

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
			update_activities = false
			if params[:name] != nil
				feed.update_columns(name: params[:name])
				update_activities = true
			end

			if params[:open] != nil
				feed.update_columns(open: params[:open])
			end

			if params[:list_description] != nil
				feed.update_columns(description: params[:list_description])
			end

			if params[:feed_color] != nil
				feed.update_columns(feed_color: params[:feed_color])
				update_activities = true
			end

			if params[:preview_image_url] != nil
				feed.update_columns(preview_image_url: params[:preview_image_url])
			end

			if params[:cover_image_url] != nil
				feed.update_columns(cover_image_url: params[:cover_image_url])
			end

			if params[:is_private] != nil
				feed.update_columns(is_private: params[:is_private])
			end

			if update_activities == true
				feed.delay(:priority => -1).update_activity_feed_related_details
			end

			render json: feed.as_json
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['No List found'] } }, status: :unprocessable_entity
		end
	end

	def populate_initial_feed
		#this call makes sure that when user opens Lytit for the first time there is activity from his underlying venue 
		#presented
		Venue.initial_list_instagram_pull(params[:venue_ids])
		render json: { success: true }
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
		@user = User.find_by_authentication_token(params[:auth_token])
		@feeds = Feed.search(params[:q])
		 #(Feed.where("LOWER(name) like (?)", params[:q].downcase+"%").includes(:feed_users).limit(10)+Feed.search(params[:q]).includes(:feed_users).limit(10)).uniq#Feed.search(params[:q]).includes(:feed_users).limit(15)
	end

	def add_feed
		feed_user = FeedUser.new(:feed_id => params[:feed_id], :user_id => params[:user_id], :creator => false)
		if feed_user.save
			Feed.delay(:priority => -1).new_member_calibration(params[:feed_id], params[:user_id])
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['User could not join List'] } }, status: :unprocessable_entity
		end
	end

	def leave_feed
		feed_user = FeedUser.where("user_id = ? AND feed_id = ?", params[:user_id], params[:feed_id]).first
		Feed.delay(:priority => -1).lost_member_calibration(params[:feed_id], params[:user_id])
		if feed_user.delete
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['User did not leave List'] } }, status: :unprocessable_entity
		end
	end

	def request_to_join
		mr = FeedJoinRequest.create!(:user_id => params[:user_id], :feed_id => params[:feed_id], :note => params[:note])
		if request
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Request did not go through'] } }, status: :unprocessable_entity
		end
	end

	def accept_join_request
		request = FeedJoinRequest.find_by_id(params[:request_id])
		if request
			request.delay(:priority => -1).accepted(true)
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Request acceptance did not go through'] } }, status: :unprocessable_entity
		end
	end

	def reject_join_request
		request = FeedJoinRequest.find_by_id(params[:request_id])
		if request
			request.accepted(false)
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Request rejection did not go through'] } }, status: :unprocessable_entity
		end
	end

	def get_members
		@feed = Feed.find_by_id(params[:id])
		@users = @feed.users.order("LOWER(name) ASC").page(params[:page]).per(10)
	end

	def get_venues
		@user = User.where("id = ?", params[:user_id]).includes(:likes).first
		@feed = Feed.find_by_id(params[:id])
		@feed_venues = @feed.feed_venues.order("num_upvotes DESC").order("venue_details ->> 'name' ASC").page(params[:page]).per(15)

		#@added_venue_activities = Activity.where("feed_id = ? AND activity_type = ?", params[:id], "added_venue").includes(:user, :venue, :feed_venue).page(params[:page]).per(15)
		#@feed_venue_activities = @feed.activities.where("activity_type = ?", "added_venue").order("venue_details ->> 'name' ASC").page(params[:page]).per(15)
		#FeedVenue.where("feed_venues.feed_id = ?", params[:id]).includes(:venue, :user, :activity).order("venues.name ASC").page(params[:page]).per(15)
	end

	def upvote_list_venue
		fv = FeedVenue.find_by_id(params[:feed_venue_id])
		upvote_user_ids = fv.upvote_user_ids
		if params[:upvote] == true
			fv.increment!(:num_upvotes, 1)
			upvote_user_ids << params[:user_id]
			fv.update_columns(upvote_user_ids: upvote_user_ids)
		else
			fv.decrement!(:num_upvotes, 1)
			upvote_user_ids.delete(params[:user_id])
			fv.update_columns(upvote_user_ids: upvote_user_ids)
		end
		render json: { success: true }
	end

	def add_venue
		params[:first_feed]
		if FeedVenue.where("feed_id = ? AND venue_id = ?", params[:id], params[:venue_id]).any? == false
			venue = Venue.find_by_id(params[:venue_id])
			@user = User.find_by_authentication_token(params[:auth_token])
			new_feed_venue = FeedVenue.new(:feed_id => params[:id], :venue_id => params[:venue_id], :user_id => params[:user_id], :description => params[:added_note], 
				:venue_details => venue.partial, :user_details => @user.partial)
			if new_feed_venue.save
				Feed.delay(:priority => -2).added_venue_calibration(params[:id], params[:venue_id])
				render json: { success: true }
			end
		else
			render json: { success: false }
		end
	end

	#Adding a venue by name.
	def add_raw_venue
		if params[:instagram_location_id] != nil
			venue = Venue.fetch_venues_for_instagram_pull(params[:name], params[:latitude], params[:longitude], params[:instagram_location_id], nil, params[:city])
		else
			venue = Venue.fetch_or_create(params[:name], params[:formatted_address], params[:city], params[:state], params[:country], params[:postal_code], params[:phone_number], params[:latitude], params[:longitude])
		end

		@user = User.find_by_authentication_token(params[:auth_token])

		if FeedVenue.where("feed_id = ? AND venue_id = ?", params[:feed_id], venue.id).any? == false
			new_feed_venue = FeedVenue.new(:feed_id => params[:feed_id], :venue_id => venue.id, :user_id => params[:user_id], :description => params[:added_note],
				:venue_details => venue.partial, :user_details => @user.partial)
			if new_feed_venue.save
				Feed.delay(:priority => -2).added_venue_calibration(params[:feed_id], venue.id)
				render json: { id: venue.id }
			end
		else
			render json: { success: false }
		end
	end

	def edit_venue_description
		fv = FeedVenue.find_by_id(params[:feed_venue_id])
		fv.description = params[:added_note]
		if fv.save
			render json: { success: false }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Could edit feed venue description'] } }, status: :unprocessable_entity
		end
	end

	def remove_activity
		if Activity.find_by_id(params[:activity_id]).delay(:priority => -8).destroy
			render json: { success: false }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Activity not removed'] } }, status: :unprocessable_entity
		end
	end

	def remove_member
		if FeedUser.find_by_user_id_and_feed_id(params[:user_id], params[:feed_id]).delay(:priority => -8).destroy
			render json: { success: false }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Member not removed'] } }, status: :unprocessable_entity
		end
	end

	def remove_venue
		feed_venue = FeedVenue.where("feed_id = ? AND venue_id = ?", params[:id], params[:venue_id]).first
		Feed.delay(:priority => -2).removed_venue_calibration(params[:id], params[:venue_id])
		feed_venue.destroy
		render json: { success: true }
	end

	def register_open
		feed = Feed.find_by_id(params[:feed_id])			
		#feed.delay.underlying_venues
		#feed.update_media	
		feed.delay.register_open(@user.id)
		render json: { success: true }
	end

	def get_feed
		@user = User.find_by_authentication_token(params[:auth_token])
		if params[:user_is_member].to_i == 0
			@join_request_exists = FeedJoinRequest.where("user_id = ? AND feed_id = ? AND granted IS NOT TRUE", @user.id, params[:feed_id]).any?
		else
			@join_request_exists = nil
		end
		@feed = Feed.find_by_id(params[:feed_id])		
	end

	def get_activity
		@user = User.where("authentication_token = ?", params[:auth_token]).includes(:likes).first
		@feed = Feed.find_by_id(params[:feed_id])
		@activities = @feed.activity_feed.page(params[:page]).per(10)
		render 'feed_activity.json.jbuilder'
	end

	def get_activity_object
		@user = User.find_by_id(params[:user_id])
		@activity = Activity.find_by_id(params[:activity_id])
		if @activity != nil
			render 'get_activity_object.json.jbuilder'
		else
			render json: nil
		end
	end

	def get_activity_lists
		@user = User.find_by_authentication_token(params[:auth_token])
		@activity = Activity.find_by_id(params[:activity_id])
		@lists = @activity.feeds.includes(:feed_users).page(params[:page]).per(10)
	end

	def get_likers
		fa = Activity.find_by_id(params[:activity_id])
		liker_ids = "SELECT liker_id FROM likes WHERE activity_id = #{fa.id}"
		@likers = User.where("id IN (#{liker_ids})").page(params[:page]).per(10)
	end

	def add_new_topic_to_feed
		feed_ids = params[:feed_ids].split(',').map(&:to_i)
		new_topic = Activity.new_list_topic(params[:user_id], params[:topic], feed_ids)
		render json: new_topic
	end

	def share_with_feed
		feed_ids = params[:feed_ids].split(',').map(&:to_i)
		new_activity = Activity.new_list_share(params[:venue_comment_details], params[:venue_comment_id], params[:venue_id], params[:user_id], feed_ids, params[:comment])
		render json: new_activity
	end

	def like_activity
		@user = User.find_by_authentication_token(params[:auth_token])
		if params[:activity_id] != nil
			fa = Activity.find_by_id(params[:activity_id])
		else
			fa = Activity.implicit_topic_activity_find(params[:user_id], params[:feed_id], params[:topic])
		end
		if Like.create!(:liker_id => params[:user_id], :liked_id => fa.user_id, :activity_id => fa.id)
			fa.increment!(:num_likes, 1)
			fa.user.increment!(:num_likes, 1)
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
			fa.user.decrement!(:num_likes, 1)
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Could not unlike feed activity'] } }, status: :unprocessable_entity
		end
	end

	def add_activity_comment
		ac = ActivityComment.create!(:activity_id => params[:activity_id], :user_id => params[:user_id], :comment => params[:comment])
		if ac
			fa = Activity.find_by_id(params[:activity_id])
			fa.update_comment_parameters(Time.now, params[:user_id])
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Could not create activity comment'] } }, status: :unprocessable_entity
		end
	end

	def delete_activity_comment
		ac = ActivityComment.find_by_id(params[:activity_comment_id])
		if ac && ac.user_id == params[:user_id]
			fa = Activity.find_by_id(params[:activity_id])
			fa.decrement!(:num_comments, 1)
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Could not delete activity comment'] } }, status: :unprocessable_entity
		end
	end

	def report_activity_comment
		ac = ActivityComment.find_by_id(params[:activity_comment_id])
		if ac.report(params[:user_id])
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Could not report activity comment'] } }, status: :unprocessable_entity
		end
	end

	def get_activity_comments		
		@activity_comments = ActivityComment.where("activity_id = ?", params[:activity_id]).includes(:user).order("id DESC").page(params[:page]).per(10)
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

	def get_list_categories
		@categories = ListCategory.all.page(params[:page]).per(20)
	end

#ADMIN Category Methods
	def get_admin_list_categories
		@feed = Feed.find_by_id(params[:feed_id])
		@categories = ListCategory.all.page(params[:page]).per(20)
	end

	def assign_categories
		category_ids = params[:category_ids].split(",")
		if ListCategoryEntry.bulk_create(category_ids, params[:feed_id])
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Category Assigned'] } }, status: :unprocessable_entity
		end
	end
#----------------------	

	def remove_categories
		category_ids = params[:category_ids].split(",")
		if ListCategoryEntry.bulk_remove(category_ids, params[:feed_id])
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Category Removed'] } }, status: :unprocessable_entity
		end
	end

	def get_lists_of_category
		lat = params[:latitude]
		long = params[:longitude]
		@feeds = Feed.of_category(params[:category], lat, long).page(params[:page]).per(20)
		render 'get_feeds.json.jbuilder'
	end

	def get_initial_recommendations
		if params[:version] == "1.1.0"
			@recommendations = FeedRecommendation.for_categories(params[:categories], params[:latitude], params[:longitude])
			render 'get_initial_recommendations'
		else
			lat = params[:latitude]
			long = params[:longitude]
			@user = User.find_by_authentication_token(params[:auth_token])
			category = params[:categories]
			category.slice!(0)
			category.slice!(category.length-1)
			@feeds = Feed.of_category(category, lat, long)#.page(params[:page]).per(10)
			render 'get_feeds.json.jbuilder'
		end
	end	

	def get_list_spotlyts
		@spotlyts = Feed.all.where("is_spotlyt IS TRUE")
		render 'get_feeds.json.jbuilder'
	end

	def get_spotlyts
		if params[:version] != "1.1.0"
			@spotlyts = Feed.all.where("in_spotlyt IS TRUE")
			render 'get_feeds.json.jbuilder'
		else
			@user = User.find_by_authentication_token(params[:auth_token])
			@spotlyts = FeedRecommendation.where("spotlyt IS TRUE").includes(:feed)
			render 'get_spotlyts.json.jbuilder'
		end
	end

	def get_daily_spotlyts
		@user = User.find_by_authentication_token(params[:auth_token])
		if params[:version] != "1.1.0"
			@feeds = Feed.all.where("in_spotlyt IS TRUE")
			render 'get_feeds.json.jbuilder'
		else			
			@spotlyts = FeedRecommendation.where("spotlyt IS TRUE").includes(:feed)
			render 'get_spotlyts.json.jbuilder'
		end
	end
	
	def get_recommendations
		@user = User.find_by_authentication_token(params[:auth_token])
		@recommendations = FeedRecommendation.for_user(@user, params[:latitude], params[:longitude])
	end

	def get_recommended_venue
		feed = Feed.find_by_id(params[:feed_id])
		@venue = feed.recommended_venue_for_user(params[:latitude], params[:longitude])	
	end	

	def invite_user
		fi = FeedInvitation.create!(:inviter_id => params[:inviter_id], :invitee_id => params[:invitee_id], :feed_id => params[:feed_id])
		if fi != nil
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Could not create invitation'] } }, status: :unprocessable_entity
		end
	end

	def report
		ro = ReportedObject.create!(:report_type=> "Feed", :feed_id => params[:feed_id], :reporter_id => params[:user_id])
		if ro 
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Report did not got through'] } }, status: :unprocessable_entity
		end
	end

end