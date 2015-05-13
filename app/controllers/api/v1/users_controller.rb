class Api::V1::UsersController < ApiBaseController
	skip_before_filter :set_user, only: [:create, :get_comments, :get_groups, :forgot_password]


	#Administrative Methods------------------>

	def create
		existing_temp_user = User.where("email = ?", params[:email]).first
		if existing_temp_user != nil && params[:email].last(8) == "temp.com"
			puts '$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ USER HAS BEEN FOUND'
			existing_temp_user.destroy
		else
			puts '&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& USER NOT FOUND'
		end

		@user = User.new(user_params)
		@user.adjusted_view_discount = LumenConstants.views_weight_adj

		if @user.save
			if @user.name.first(10).downcase == @user.email.first(10).downcase && @user.email.last(8) == "temp.com"
				@user.vendor_id = @user.name
				@user.name = "lyt_"+(@user.id*2+Time.now.day).to_s(16)
				temp_user = true
				@user.save
			end

			if VendorIdTracker.where("used_vendor_id = ?", @user.vendor_id).first == nil
				l = LumenValue.new(:value => 5.0, :user_id => @user.id, :media_type => "bonus")
      			l.save
      			@user.lumens = 5.0
      			@user.bonus_lumens = 5.0
      			@user.save
      			v_id_tracker = VendorIdTracker.new(:used_vendor_id => @user.vendor_id)
      			v_id_tracker.save
      		end
			sign_in @user

			render 'created.json.jbuilder'
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: @user.errors.full_messages } }, status: :unprocessable_entity
		end
	end

	def destroy_previous_temp_user
		previous_user = User.where("vendor_id = ? AND registered = FALSE", params[:vendor_id]).first
		user_bounties = previous_user.bounties
		if user_bounties.count > 0
			for bounty in user_bounties
				bounty.venue.decrement!(:outstanding_bounties, 1)
				bounty.destroy
			end
		end
		previous_user.destroy
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
		User.where(push_token: params[:push_token]).update_all(push_token: nil)
		@user.update(push_token: params[:push_token])
		render 'created.json.jbuilder'
	end

	def register_gcm_token
		User.where(gcm_token: params[:gcm_token]).update_all(gcm_token: nil)
		@user.update(gcm_token: params[:gcm_token])
		render 'created.json.jbuilder'
	end

	def username_availability
		@response = User.where("LOWER(name) = ?", params[:q].to_s.downcase).any?
		render json: { bool_response: @response }
	end

	def email_availability
		@response = User.where("LOWER(email) = ?", params[:q].to_s.downcase).any?
		render json: { bool_response: @response }
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

	def is_user_confirmed
		@user = User.find_by_authentication_token(params[:auth_token])
		confirmation_status = @user.email_confirmed
		render json: {bool_response: confirmation_status }
	end	

	def validate_coupon_code
		@user = User.find_by_authentication_token(params[:auth_token])
		@validation_message = Coupon.check_code(params[:coupon_code], @user)
		render json: { validation_message: @validation_message }
	end

	def confirm_email
		user = User.find_by_confirm_token(params[:id])
		if user
			user.email_activate
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


	#Usage Methods------------------>

	def get_map_details
		@user = User.find_by_id(params[:user_id])
		render 'get_map_details.json.jbuilder'
	end

	def get_surprise_image
		@user = User.find_by_authentication_token(params[:auth_token])
		render json: { validation_message: @user.surprise_image_url }
	end

	def get_bounties
		@user = User.find_by_authentication_token(params[:auth_token])
		total_bounties = @user.total_user_bounties
		@bounties = []
		for bounty in total_bounties
			if (bounty.user_id == @user.id && bounty.check_validity == true) || (bounty.user_id != @user.id)
				@bounties << bounty
			end
		end
	end

	def get_bounty_claims
		@bounty_claims = VenueComment.where("is_response = TRUE and user_id = #{params[:user_id]} AND (NOW() - created_at) <= INTERVAL '1 DAY'").includes(:bounty, :venue).order('id DESC')
	end

	def get_venue_comment
		@venue_comment = VenueComment.find_by_id(params[:venue_comment_id])
	end

	def get_surrounding_feed
		feed = @user.global_feed
		@surrounding_feed = Kaminari.paginate_array(feed).page(params[:page]).per(10)
	end

	def can_claim_bounties
		render json: { bool_response: @user.can_claim_bounties? } 
	end

	#As related to Lumens
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

	private

	def user_params
		params.permit(:name, :version, :email, :password, :notify_location_added_to_groups, :notify_events_added_to_groups, :notify_venue_added_to_groups, :username_private)
	end
end

