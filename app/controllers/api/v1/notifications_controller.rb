class Api::V1::NotificationsController < ApiBaseController
  
  def index
    @notifications = Notification.where(user_id: @user.id)
  end

end