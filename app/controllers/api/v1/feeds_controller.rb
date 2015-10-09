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
		@feeds = Feed.where("LOWER(name) LIKE ?", '%' + params[:q].to_s.downcase + '%').limit(15)
	end

	def add_feed
		feed = Feed.find_by_id(params[:feed_id])
		feed.calibrate_num_members
		feed.increment!(:num_users, 1)

		feed_user = FeedUser.new(:feed_id => feed.id, :user_id => params[:user_id], :creator => false)
		feed_user.save
		render json: { success: true }
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
		@user = User.find_by_authentication_token(params[:auth_token]).includes(:likes)
		@feed = Feed.find_by_id(params[:id])
		@venues = @feed.venues.includes(:feed_venues)
	end

	def add_venue
		if FeedVenue.where("feed_id = ? AND venue_id = ?", params[:id], params[:venue_id]).any? == false
			new_feed_venue = FeedVenue.new(:feed_id => params[:id], :venue_id => params[:venue_id], :user_id => params[:user_id], :description => params[:description])
			if new_feed_venue.save
				feed = Feed.find_by_id(params[:id])
				feed.increment!(:num_venues, 1)
				venue = Venue.find_by_id(params[:venue_id])
				feed.delay.convert_added_venue_vcs_to_activities(venue)
				render json: { success: true }
			end
		else
			render json: { success: false }
		end
	end

	#Adding a venue by name.
	def add_raw_venue
		venue = Venue.fetch(params[:name], params[:formatted_address], params[:city], params[:state], params[:country], params[:postal_code], params[:phone_number], params[:latitude], params[:longitude], params[:pin_drop])
		if FeedVenue.where("feed_id = ? AND venue_id = ?", params[:feed_id], venue.id).any? == false
			new_feed_venue = FeedVenue.new(:feed_id => params[:feed_id], :venue_id => venue.id, :user_id => params[:user_id], :description => params[:description])
			if new_feed_venue.save
				feed = Feed.find_by_id(params[:feed_id])
				feed.increment!(:num_venues, 1)
				feed.delay.convert_added_venue_vcs_to_activities(venue)
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

	def send_message
		#This is to deal with instances when a user tries to share a directly dispalyed instagram which does not have an associated venue_comment at the time
		if params[:venue_comment_details] != nil
			venue_comment_id = VenueComment.convert_instagram_details_to_vc(params[:venue_comment_details])
		else
			venue_comment_id = params[:venue_comment_id]
		end

		feed_ids = params[:feed_ids].split(',').map(&:to_i)
		if feed_ids.count == 1
			new_message = FeedMessage.create!(:message => params[:chat_message], :feed_id => feed_ids.first, :user_id => params[:user_id], :venue_comment_id => venue_comment_id)
			render json: { success: true }
		else
			for feed_id in feed_ids
				FeedMessage.create!(:message => params[:chat_message], :feed_id => feed_id, :user_id => params[:user_id], :venue_comment_id => venue_comment_id)
			end
			render json: { success: true }
		end
	end

	def get_chat
		@user = User.find_by_authentication_token(params[:auth_token])
		chat_messages = FeedMessage.where("feed_id = ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", params[:feed_id]).order("id DESC")
		@messages = chat_messages.page(params[:page]).per(15)
	end

	def get_activity
		@user = User.find_by_authentication_token(params[:auth_token])
		@feed = Feed.find_by_id(params[:feed_id])
		@activities = Kaminari.paginate_array(@feed.activity).page(params[:page]).per(10)
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