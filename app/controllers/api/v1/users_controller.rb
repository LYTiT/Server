class Api::V1::UsersController < ApiBaseController
	skip_before_filter :set_user, only: [:create, :get_comments, :get_groups, :forgot_password]

	def create
		@user = User.new(user_params)
		@user.adjusted_view_discount = LumenConstants.views_weight_adj

		if @user.save
			if @user.name.first(10).downcase == @user.email.first(10).downcase && @user.email.last(8) == "temp.com"
				@user.vendor_id = @user.name
				@user.name = "lyt_"+(@user.id*2+Time.now.day).to_s(16)
				temp_user = true
				@user.save
			end 
			sign_in @user

			render 'created.json.jbuilder'
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: @user.errors.full_messages } }, status: :unprocessable_entity
		end
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

	def destroy_previous_temp_user
		previous_user = User.where("vendor_id = ? AND registered = FALSE", params[:vendor_id]).first
		previous_user.destroy
		render json: { success: true }
	end

	def confirm_email
		user = User.find_by_confirm_token(params[:id])
		if user
			user.email_activate
		end
	end

	def get_map_details
		@user = User.find_by_id(params[:user_id])
		render 'get_map_details.json.jbuilder'
	end

	def set_version
		@user = User.find_by_id(params[:user_id])
		v = params[:version]
		if v.count(".") == 1
			v = v + ".0"
		end
		@user.set_version(v)
		render json: { success: true }
	end

	def get_bounties
		subcribed_bounty_ids = "SELECT bounty_id FROM bounty_subscribers WHERE user_id = #{params[:user_id]}"
		raw_bounties = Bounty.where("(user_id = ? OR id IN (#{subcribed_bounty_ids})) AND validity = true", params[:user_id]).includes(:venue).order('id DESC')
		@bounties = []
		for bounty in raw_bounties
			if bounty.check_validity == true
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

	def get_comments
		@user = User.find_by_id(params[:user_id])
		if not @user
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["User not found"] } }, :status => :not_found
		else
			@comments = @user.venue_comments.includes(:venue, :groups_venue_comments).page(params[:page]).per(12).order("created_at desc")
		end
	end

	def get_groups
		@user = User.find_by_id(params[:user_id])
		if not @user
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["User not found"] } }, :status => :not_found
		end
		@groups = @user.groups.includes(:groups_users).order("name ASC")
	end

	def get_a_users_profile
		@user = User.find_by_id(params[:user_id])
		if not @user
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["User not found"] } }, :status => :not_found
		else
			v = @user.venue_comments.where("username_private = 'false'")
			@comments = v.page(params[:page]).per(5).order("created_at desc")
		end
	end

	def get_linkable_groups
		@user = User.find_by_id(params[:user_id])
		if not @user
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["User not found"] } }, :status => :not_found
		else
			@groups = @user.linkable_groups.includes(:groups_users, :groups_venues).order("Name ASC")
		end
	end

	def get_surrounding_feed
		@user = User.find_by_id(params[:user_id])
		feed = @user.global_feed
		@surrounding_feed = Kaminari.paginate_array(feed).page(params[:page]).per(10)
	end

	def is_member
		@group = Group.find_by_id(params[:group_id])
		@membership = @group.is_user_member?(params[:user_id])
		render json: { bool_response: @membership }
	end

	def can_claim_bounties
		@user = User.find_by_id(params[:user_id])
		render json: { bool_response: @user.can_claim_bounties? } 
	end

	def following
		user = User.find(params[:user_id])
		@followed_users = user.followed_users.order("Name ASC")
	end

	def followers
		@user = User.find(params[:user_id])
		@followers = @user.followers.order("Name ASC")
	end

	def get_followers_for_invite
		@user = User.find(params[:user_id])
		@prospects = @user.followers_not_in_group(params[:group_id])
	end

	def get_following_for_invite
		@user = User.find(params[:user_id])
		@prospects = @user.following_not_in_group(params[:group_id])
	end  

	def vfollowing
		user = User.find(params[:user_id])
		@followed_venues = user.followed_venues.order("Name ASC")
	end

	def is_following_user
		@other_user = User.find_by_id(params[:user_id])
		@user = User.find_by_authentication_token(params[:auth_token])
	end

	def is_following_venue
		@venue = Venue.find_by_id(params[:user_id])
		@user = User.find_by_authentication_token(params[:auth_token])
	end

	def get_feed
		@user = User.find_by_id(params[:user_id])
		if not @user
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["User not found"] } }, :status => :not_found
		else
			feed = @user.viewing_feed
			@news = Kaminari.paginate_array(feed).page(params[:page]).per(10)
		end
	end

	def get_list_of_places_mapped
		@user = User.find_by_id(params[:user_id])
		@places = @user.list_of_places_mapped
	end

	def get_venue_comments_from_venue
		@user = User.find_by_id(params[:user_id])
		vcs = @user.venue_comments_from_venue(params[:venue_id])
		@comments = Kaminari.paginate_array(vcs).page(params[:page]).per(5)
	end

	def get_recommended_users
		@user = User.find_by_id(params[:user_id])
		@top_users = @user.top_posting_users
	end

	def username_availability
		@response = User.where("LOWER(name) = ?", params[:q].to_s.downcase).any?
		render json: { bool_response: @response }
	end

	def email_availability
		@response = User.where("LOWER(email) = ?", params[:q].to_s.downcase).any?
		render json: { bool_response: @response }
	end

	def search
		@user = User.find_by_authentication_token(params[:auth_token])
		if User.where("name = ?", params[:q].to_s).any?
			@person = User.where("name = ?", params[:q].to_s).includes(:relationships)
		else
			@person = User.where("name = ? OR LOWER(name) like ?", params[:q].to_s, '%' + params[:q].to_s.downcase + '%').includes(:relationships)
		end
		@person = @person[0...10]  
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

	#As related to Lumens
	def calculate_lumens
		@user = User.find(params[:user_id])
		@user.calculate_lumens()
	end

	def get_lumens
		@user = User.find(params[:user_id])
	end

	def get_daily_lumens
		@user = User.find(params[:user_id])
	end

	def get_lumen_notification_details
		@user = User.find(params[:user_id])
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

	def toggle_group_notification
		status, message = @user.toggle_group_notification(params[:group_id], params[:enabled])
		if status
			render json: { success: true }
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: [message]} }, status: :unprocessable_entity
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

	private

	def user_params
		params.permit(:name, :version, :email, :password, :notify_location_added_to_groups, :notify_events_added_to_groups, :notify_venue_added_to_groups, :username_private)
	end
end

