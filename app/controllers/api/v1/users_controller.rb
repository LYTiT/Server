class Api::V1::UsersController < ApiBaseController
  skip_before_filter :set_user, only: [:create, :get_comments, :get_groups, :forgot_password]

  def create
    @user = User.new(user_params)

    if @user.save
      sign_in @user
      Mailer.delay.welcome_user(@user)
      render 'created.json.jbuilder'
    else
      render json: { error: { code: ERROR_UNPROCESSABLE, messages: @user.errors.full_messages } }, status: :unprocessable_entity
    end
  end

  def set_version
    @user = User.find_by_id(params[:user_id])
    @user.set_version(params[:version])
    render json: { success: true }
  end
  
  def get_comments
    @user = User.find_by_id(params[:user_id])
    if not @user
      render json: { error: { code: ERROR_NOT_FOUND, messages: ["User not found"] } }, :status => :not_found
    else
      @comments = @user.venue_comments.page(params[:page]).per(12).order("created_at desc")
    end
  end

  def get_bounties
    @user = User.find_by_id(params[:user_id])
    @bounties = @user.bounties.order('id ASC')
  end

  def get_groups
    @user = User.find_by_id(params[:user_id])
    if not @user
      render json: { error: { code: ERROR_NOT_FOUND, messages: ["User not found"] } }, :status => :not_found
    end
  end

  def get_linkable_groups
    @user = User.find_by_id(params[:user_id])
    if not @user
      render json: { error: { code: ERROR_NOT_FOUND, messages: ["User not found"] } }, :status => :not_found
    else
      @groups = @user.linkable_groups(@user.groups.to_a)
    end
  end

  def is_member
    @group = Group.find_by_id(params[:group_id])
    @membership = @group.is_user_member?(params[:user_id])
    render json: { bool_response: @membership }
  end

  def following
    #@title = "Following"
    user = User.find(params[:user_id])
    @followed_users = user.followed_users.sort_by{|following| following.name.downcase}
    #@users = @user.followed_users.paginate(page: params[:page])
  end

  def followers
    #@title = followers
    @user = User.find(params[:user_id])
    @followers = @user.followers.sort_by{|followers| followers.name.downcase}
    #@users = @user.followers.paginate(page: params[:page])
  end

  def get_followers_for_invite
    @user = User.find(params[:user_id])
    @prospects = @user.followers_not_in_group(@user.followers.to_a, params[:group_id])
  end

  def vfollowing
    user = User.find(params[:user_id])
    @followed_venues = user.followed_venues.sort_by{|following| following.name.downcase}
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

    feed = @user.totalfeed
    @news = Kaminari.paginate_array(feed).page(params[:page]).per(5) #.order("updated_at desc")  User.search(params[:query]).page(params[:page]).records.activated.page(params[:page])
    end
  end

  def posting_kill_request
    @user = User.find_by_id(params[:user_id])
    @user.posting_kill_request
    render json: { success: true }
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
    @user.lumens 
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

