class Api::V1::UsersController < ApiBaseController
	skip_before_filter :set_user, only: [:create, :get_comments, :get_groups, :forgot_password]

	#Administrative/Creation Methods------------------>

	def username_availability
		@response = User.where("LOWER(name) = ?", params[:q].to_s.downcase).any?
		render json: { bool_response: !@response }
	end

	def email_availability
		@response = User.where("LOWER(email) = ?", params[:q].to_s.downcase).any?
		render json: { bool_response: !@response }
	end

	def confirm_password
		@user = User.find_by_authentication_token(params[:auth_token])
		@response = @user.authenticated?(params[:password])
		render json: { bool_response: @response }
	end

	def create
		#begin
			existing_temp_user = User.where("email = ?", params[:email]).first
			if (existing_temp_user != nil && params[:email].last(8) == "temp.com")
				if existing_temp_user.registered != true
					existing_temp_user.delete
				else
					previous_email = existing_temp_user.email
					#duplicates cannot exist in database thus must modifiy email which vendor id based which is unique per phone
					existing_temp_user.update_columns(email: previous_email+"#{Time.now.min}#{Time.now.sec}"+".og")
				end
			end
		#rescue
		#	puts "Previous temp user issue"
		#end

		@user = User.new(user_params)

		if @user.save
			if @user.name.first(10).downcase == @user.email.first(10).downcase && (@user.email.last(8) == "temp.com" || @user.email.last(3) == ".og")
				name = @user.name
				id = @user.id
				@user.update_columns(vendor_id: name)
				@user.update_columns(name: "lyt_"+(id*2+3).to_s(16))

				#@user.vendor_id = @user.name
				#@user.name = "lyt_"+(@user.id*2+3).to_s(16)
				#temp_user = true
				#@user.save
			end

			#SupportIssue.delay.create!(user_id: @user.id)
			VendorIdTracker.delay.implicit_creation(@user.id)

			sign_in @user
			render 'created.json.jbuilder'
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: @user.errors.full_messages } }, status: :unprocessable_entity
		end
	end

	def register
		@user = User.find_by_authentication_token(params[:auth_token])
		@user.name = params[:name]
		@user.phone_number = params[:phone_number]
		@user.country_code = params[:country_code]
		if params[:password] != nil
			@user.password = params[:password]
		end

		@user.registered = true
		if @user.save		
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: "Could not register user"} }, status: :unprocessable_entity
		end
	end

	def update_user
		@user = User.find_by_authentication_token(params[:auth_token])
		if params[:name] != nil && params[:name] != @user.name
			@user.name = params[:name]
		end

		if params[:phone_number] != nil and params[:phone_number].to_s != @user.phone_number
			@user.phone_number = params[:phone_number].to_s
			@user.country_code = params[:country_code].to_s
		end

		if params[:profile_image_url] != nil
			@user.profile_image_url = params[:profile_image_url]
		end

		if params[:profile_description] != nil
			@user.profile_description = params[:profile_description]
		end

		if params[:num_daily_moments] != nil
			if params[:num_daily_moments].to_i < 25 
				@user.num_daily_moments = params[:num_daily_moments]
			else
				@user.num_daily_moments = nil
			end
		end

		if @user.save		
			@user.delay(:priority => -1).update_list_activity_user_details
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: "User cannot be updated with given parameters"} }, status: :unprocessable_entity
		end
	end

	def refresh_user
		@user = User.find_by_authentication_token(params[:auth_token])
		render 'created.json.jbuilder'
	end

	def set_email_password
		@user = User.find_by_authentication_token(params[:auth_token])
		if (params[:email] != nil and params[:email].length > 4) && @user.email != params[:email]
			@user.email = params[:email]
		end
		#nilify the phone number so the user will have to reconfirm upon future login (can only be logged in on one device)
		if params[:password] != nil
			@user.password = params[:password]
		end		

		if @user.save
			#Mailer.delay.welcome_user(@user)
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: "Could update user fields"} }, status: :unprocessable_entity
		end
	end

	def user_sign_out
		@user = User.find_by_authentication_token(params[:auth_token])
		if (params[:email] != nil and params[:email].length > 4) && @user.email != params[:email]
			@user.email = params[:email]
		end

		if params[:password] != nil
			@user.password = params[:password]
		end
		#to disable push notification that might be sent from underlying Lists
		@user.active = false

		if @user.save
			sign_out
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: "Could not sign out user"} }, status: :unprocessable_entity
		end
	end

	def set_facebook_id
		@user.update_columns(facebook_id: params[:fb_id])
		@user.update_columns(facebook_name: params[:fb_name])
		@user.notify_friends_of_joining(params[:fb_friend_ids], params[:fb_name], params[:fb_id])
		render json: { success: true }
	end

	def set_version
		#@user = User.find_by_authentication_token(params[:auth_token])
		#v = params[:version]
		#if v.count(".") == 1
		#	v = v + ".0"
		#end
		#@user.set_version(v)
		render json: { success: true }
	end	

	def update_phone_number
		user = User.find_by_authentication_token(params[:auth_token])
		user.update_columns(phone_number: params[:phone_number])
		user.update_columns(country_code: params[:country_code])
		render json: { success: true }
	end

	def get_lytit_facebook_friends
		@users = @user.lytit_facebook_friends(params[:fb_friend_ids]).page(params[:page]).per(10)
	end

	def get_lytit_facebook_friends
		@users = @user.lytit_facebook_friends(params[:fb_friend_ids]).page(params[:page]).per(10)
		if params[:feed_id] != nil
			@feed = Feed.find_by_id(params[:feed_id])
			render "cross_reference_user_phonebook_for_invitation.json.jbuilder"
		else
			render "cross_reference_user_phonebook.json.jbuilder"
		end		
	end

	def cross_reference_user_phonebook
		user_phonebook = params[:phone_numbers].split(",")
		@users = User.find_lytit_users_in_phonebook(user_phonebook)
		if params[:feed_id] != nil
			@feed = Feed.find_by_id(params[:feed_id])
			render "cross_reference_user_phonebook_for_invitation.json.jbuilder"
		else
			render "cross_reference_user_phonebook.json.jbuilder"
		end
	end

	def register_push_token
		User.where(push_token: params[:push_token]).update_all(push_token: nil)
		@user.update_columns(push_token: params[:push_token])
		render 'created.json.jbuilder'
	end

	def register_gcm_token
		User.where(gcm_token: params[:gcm_token]).update_all(gcm_token: nil)
		@user.update(gcm_token: params[:gcm_token])
		render 'created.json.jbuilder'
	end

	def change_password
		if User.authenticate(@user.email, params[:old_password])
			if @user.update_password(params[:new_password])
				render 'created.json.jbuilder'
			else
				render json: { error: { code: ERROR_UNPROCESSABLE, messages: @user.errors.full_messages } }, status: :unprocessable_entity
			end
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Old password do not match']}  }, status: :unprocessable_entity
		end
	end

	def forgot_password
		user = User.find_by_email(params[:email])
		if user
			user.forgot_password!
			::ClearanceMailer.change_password(user).deliver
			render json: { success: true, message: 'Password reset link sent to your email.' }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Can not find user with this email'] } }, status: :unprocessable_entity
		end
	end

	def is_user_confirmed
		@user = User.find_by_authentication_token(params[:auth_token])
		confirmation_status = @user.email_confirmed
		render json: {bool_response: confirmation_status }
	end	

	def confirm_email
		user = User.find_by_confirm_token(params[:id])
		if user
			user.email_activate
		end
	end

	def add_instagram_auth_token
		pass = false
		existence_check = InstagramAuthToken.where("instagram_user_id = ?", params[:instagram_user_id]).first
		if existence_check != nil
			existence_check.update_columns(token: params[:instagram_user_token])
			existence_check.update_columns(is_valid: true)
			existence_check.update_columns(user_id: params[:user_id])
			existence_check.update_columns(num_used: 0)
			pass = true
		else
			instagram_auth_token = InstagramAuthToken.create!(token: params[:instagram_user_token], instagram_user_id: params[:instagram_user_id], instagram_username: params[:instagram_user_name], user_id: params[:user_id])
			pass = true
		end
		render json: { success: pass }
	end

	def remove_instagram_authentication
		inst_auth_token = InstagramAuthToken.where("instagram_user_id = ?", params[:instagram_user_id]).first
		inst_auth_token.update_columns(instagram_user_id: nil)
		render json: { success: true }
	end

	def update_instagram_permission
		user = User.find_by_authentication_token(params[:auth_token])
		user.update_columns(asked_instagram_permission: true)
		render json: { success: true }
	end

	def check_instagram_token_expiration
		user = User.find_by_authentication_token(params[:auth_token]) 
		if user.instagram_auth_tokens.first.try(:is_valid) == false
			render json: { bool_response: true }
		else
			render json: { bool_response: false }
		end
	end
	#-------------------------------------------------------------------------------->
	#-------------------------------------------------------------------------------->
	#-------------------------------------------------------------------------------->
	#Functionality Methods----------------------------------------------------------->
	def get_map_details
		@user = User.find_by_id(params[:user_id])
		render 'get_map_details.json.jbuilder'
	end

	def get_startup_details
		@user = User.find_by_id(params[:user_id])
		@user.delay(:priority => -3).update_user_feeds
		render 'get_startup_details.json.jbuilder'
	end

	def get_user_feeds
		#we use this method to also return list of feeds when inside a venue page(params[:venue_id]) and so must make a check if the venue is part of any of the user's feed.
		@viewer = User.find_by_authentication_token(params[:auth_token])
		@user = User.find_by_id(params[:user_id]) 
		@venue_id = params[:venue_id]
		@num_likes = @user.num_likes #HACK ALERT: This is placed into each List that is returned, need to return seperately

		@feeds = Kaminari.paginate_array(@user.feeds.includes(:user, :feed_venues, :feed_users).where("feeds.user_id = ?", @user.id).order("LOWER(name) asc")+@user.feeds.includes(:user, :feed_venues, :feed_users).where("feeds.user_id != ?", @user.id).order("LOWER(name) asc")).page(params[:page]).per(20)
	end

	def get_daily_posts
		@comments = @user.venue_comments.where("adjusted_sort_position > ?", (Time.now-1.day).to_i).order("id DESC").page(params[:page]).per(10)
	end

	def toggle_group_notification
		status, message = @user.toggle_group_notification(params[:group_id], params[:enabled])
		if status
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: [message]} }, status: :unprocessable_entity
		end
	end

	def get_aggregate_activity
		@user = User.where("authentication_token = ?", params[:auth_token]).includes(:likes).first
		@activities = @user.aggregate_list_feed.page(params[:page]).per(10)		
	end

	def get_list_feed
		@user = User.where("authentication_token = ?", params[:auth_token]).includes(:likes).first
		@activities = @user.aggregate_list_feed.page(params[:page]).per(10)
		render 'lists_feed.json.jbuilder'
	end

	def get_list_recommendations
		cache_key = "user/#{@user.id}/list_recommendations"
		@recommendations = Rails.cache.fetch(cache_key, :expires_in => 24.hours) do
			FeedRecommendation.for_user(@user, params[:latitude], params[:longitude]).limit(10)
		end
		@user.delay(:priority => -3).update_user_feeds
	end

	def get_nearby_venues
		@venues = []#@user.surrounding_venues(params[:latitude], params[:longitude])
		if @venues.first.is_a?(Hash) 
			render 'nearby_venues_dirty.json.jbuilder'
		else
			render 'nearby_venues_pure.json.jbuilder'
		end
	end

	def get_trending_venues
		lat = params[:latitude]
		long = params[:longitude]
		search_box = Geokit::Bounds.from_point_and_radius([lat,long], 20, :units => :kms)
		nearby_vortex = InstagramVortex.in_bounds(search_box).order("id ASC").first
		
		if nearby_vortex != nil
			cache_key = "trending_venues/[#{nearby_vortex.latitude},#{nearby_vortex.longitude}]"
		else
			cache_key = "trending_venues/[#{lat},#{long}]"
		end
		
		@venues = Rails.cache.fetch(cache_key, :expires_in => 30.minutes) do
			Venue.trending_venues(lat, long)
		end
		@view_cache_key = cache_key+"/view"
	end

	def get_happening_venue_recs
		@user = User.find_by_authentication_token(params[:auth_token])
		#@venues = Venue.where("color_rating > 0").limit(15)
		@venues = Venue.live_recommendation_for(@user, params[:latitude], params[:longitude])
	end

	def get_interests
		@user = User.find_by_authentication_token(params[:auth_token])
		@interests = @user.top_interests
		render 'user_interests.json.jbuilder'
	end

	def get_suggested_interests
		@user = User.find_by_authentication_token(params[:auth_token])
		@interests = @user.suggested_interests.page(params[:page].to_i, 40)
		render 'user_interests.json.jbuilder'
	end

	def add_interest
		@user = User.find_by_authentication_token(params[:auth_token])
		if @user.add_interest(params[:interest])
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Interest added'] } }, status: :unprocessable_entity
		end		
	end

	def remove_interest
		@user = User.find_by_authentication_token(params[:auth_token])
		if @user.remove_interest(params[:interest])
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Interest successfully removed'] } }, status: :unprocessable_entity
		end			
	end

	def get_user
		@user = User.find_by_id(params[:user_id])		
	end


	#-------------------------------------------------->

	def report_user
		ro = ReportedObject.create!(:report_type=> "User", :user_id => params[:user_id], :reporter_id => params[:reporter_id])
		if ro 
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: ['Report did not got through'] } }, status: :unprocessable_entity
		end
	end	

	def get_top_favorite_venues
		@top_favorite_venues = @user.top_favorite_venues
	end

	def get_favorite_venues
		@user = User.find_by_authentication_token(params[:auth_token])
		@favorite_venues = @user.favorite_venues.order("venue_name ASC").page(params[:page]).per(10)
	end

	def get_venue_comments
		@comments = @user.venue_comments.where("created_at > ?", Time.now-1.day).order("id DESC").page(params[:page]).per(10)
	end

	private

	def user_params
		params.permit(:name, :version, :email, :password, :username_private)
	end
end

