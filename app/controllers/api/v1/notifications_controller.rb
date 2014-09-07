class Api::V1::NotificationsController < ApiBaseController
  
  def index
    @notifications = Notification.where(user_id: @user.id)
  end

  def mark_as_read
    notification = Notification.where(id: params[:notification_id], user_id: @user.id).first
    if notification.present?
      notification[:read] = true
      notification.save
      render json: { success: true }
    else
      render json: { error: { code: ERROR_NOT_FOUND, messages: ["Notification/User not found"] } }, :status => :not_found
    end
  end

end