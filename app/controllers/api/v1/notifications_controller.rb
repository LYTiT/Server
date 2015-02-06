class Api::V1::NotificationsController < ApiBaseController
  
  def index
    @notifications = Notification.where(user_id: @user.id, deleted: false)
  end

  def destroy
    notification = Notification.where(id: params[:id], user_id: @user.id, deleted: false).first
    if notification.present?
      notification[:deleted] = true
      notification.save
      render json: { success: true }
    else
      render json: { error: { code: ERROR_NOT_FOUND, messages: ["Notification/User not found"] } }, :status => :not_found
    end
  end

  def mark_as_read
    notification = Notification.where(id: params[:notification_id], user_id: @user.id, deleted: false).first
    if notification.present?
      notification[:read] = true
      notification.save
      render json: { success: true }
    else
      render json: { error: { code: ERROR_NOT_FOUND, messages: ["Notification/User not found"] } }, :status => :not_found
    end
  end

  def multiple_delete
    for notification in params[:notifications_to_delete]
      Notification.where(id: notification["id"], user_id: @user.id, deleted: false)
      notification[:deleted] = true
      notification.save
    end
    render json: { success: true }
  end

end