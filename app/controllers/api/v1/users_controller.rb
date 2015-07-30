class Api::V1::UsersController < ApiBaseController
	skip_before_filter :set_user, only: [:create, :get_comments, :get_groups, :forgot_password]


	#Administrative/Creation Methods------------------>

	def username_availability
		@response = User.where("LOWER(name) = ?", params[:q].to_s.downcase).any?
		render json: { bool_response: @response }
	end

	def email_availability
		@response = User.where("LOWER(email) = ?", params[:q].to_s.downcase).any?
		render json: { bool_response: @response }
	end

	def create
		existing_temp_user = User.where("email = ?", params[:email]).first
		if existing_temp_user != nil && params[:email].last(8) == "temp.com"
			existing_temp_user.destroy
		end

		@user = User.new(user_params)
		@user.adjusted_view_discount = LumenConstants.views_weight_adj

		if @user.save
			if @user.name.first(10).downcase == @user.email.first(10).downcase && @user.email.last(8) == "temp.com"
				@user.vendor_id = @user.name
				@user.name = "lyt_"+(@user.id*2+3).to_s(16)
				temp_user = true
				@user.save
			end

			if VendorIdTracker.where("LOWER(used_vendor_id) = ?", @user.vendor_id.downcase).first == nil
      			v_id_tracker = VendorIdTracker.new(:used_vendor_id => @user.vendor_id)
      			v_id_tracker.save
      		end
			sign_in @user
			#check if there are lyts around a user and if not make an instagram pull to drop them (if there are any instagrams created in the area)
			Venue.delay.instagram_content_pull(params[:latitude], params[:longitude])
			render 'created.json.jbuilder'
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: @user.errors.full_messages } }, status: :unprocessable_entity
		end
	end

	def destroy_previous_temp_user
		previous_user = User.where("vendor_id = ? AND registered = FALSE", params[:vendor_id]).first
		if previous_user != nil
			previous_user.destroy
		end
		render json: { success: true }
	end

	def register
		@user = User.find_by_authentication_token(params[:auth_token])
		@user.name = params[:username]
		@user.email = params[:email]
		@user.password = params[:password]
		@user.registered = true
		@user.save
		Mailer.delay.welcome_user(@user)
		render json: { success: true }
	end

	def set_version
		@user = User.find_by_authentication_token(params[:auth_token])
		v = params[:version]
		if v.count(".") == 1
			v = v + ".0"
		end
		@user.set_version(v)
		render json: { success: true }
	end	

	def register_push_token
		#User.where(push_token: params[:push_token]).update_all(push_token: nil)
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

	def update
		@user = User.find params[:id]
		permitted_params = user_params
		permitted_params.delete(:password)

		if @user.update_attributes(permitted_params)
			render 'created.json.jbuilder'
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: @user.errors.full_messages } }, status: :unprocessable_entity
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
		existence_check = InstagramAuthToken.where("instagram_user_id = ?", params[:instagram_user_id]).first
		if existence_check != nil
			existence_check.update_columns(token: params[:instagram_user_token])
			existence_check.update_columns(is_valid: true)
			existence_check.update_columns(user_id: params[:user_id])
			existence_check.update_columns(num_used: 0)
		else
			instagram_auth_token = InstagramAuthToken.create!(token: params[:instagram_user_token], instagram_user_id: params[:instagram_user_id], instagram_username: params[:instagram_user_name], user_id: params[:user_id])
		end
		render json: { success: true }
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
	#--------------------------------------------------->


	#Functionality Methods------------------------------>
	def get_map_details
		@user = User.find_by_id(params[:user_id])
		render 'get_map_details.json.jbuilder'
	end

	def get_comments_by_time
		venue_comments = @user.venue_comments.includes(:venue).order("id desc")
		@comments = venue_comments.page(params[:page]).per(12)
	end

	def get_comments_by_venue
		venue_comments = @user.venue_comments.joins(:venue).order("venues.name asc").order("id desc")
		@comments = venue_comments.page(params[:page]).per(12)
	end

	def get_user_feeds
		#we use this method to also return list of feeds when inside a venue page(params[:venue_id]) and so must make a check if the venue is part of any of the user's feed.
		@user = User.find_by_authentication_token(params[:auth_token])
		if params[:venue_id] == nil
			@user.delay.update_user_feeds
		end
		@venue_id = params[:venue_id]
		@feeds = @user.feeds.includes(:venues).order("name asc")
	end

	def calculate_lumens
		@user = User.find(params[:user_id])
		@user.calculate_lumens()
	end

	def get_lumens
		@user = User.find(params[:user_id])
		@user.lumen_rank
	end

	def get_daily_lumens
		@user = User.find(params[:user_id])
	end

	def get_lumen_notification_details
		@user = User.find(params[:user_id])
	end

	def toggle_group_notification
		status, message = @user.toggle_group_notification(params[:group_id], params[:enabled])
		if status
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: [message]} }, status: :unprocessable_entity
		end
	end
	#-------------------------------------------------->

	private

	def user_params
		params.permit(:name, :version, :email, :password, :notify_location_added_to_groups, :notify_events_added_to_groups, :notify_venue_added_to_groups, :username_private)
	end
end

