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

	def bulk_destroy
		notification_ids = params[:notification_ids].split(",")
		if Notification.bulk_destroy(notification_ids)
			render json: { success: true }
		else
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["Notifications not destoryed"] } }, :status => :not_found
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

	def mark_feedchat_as_read
		notifications = Notification.where(payload: {feed_id: params[:feed_id]}, user_id: @user.id, deleted: false)
		for notification in notifications
			notification[:deleted] = true
			notification.save
		end
		render json: { success: true }
	end

	def mark_as_responded_to
		notification = Notification.where(id: params[:notification_id], user_id: @user.id, deleted: false).first
		if notification.present?
			notification[:responded_to] = true
			notification.save
			render json: { success: true }
		else
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["Notification/User not found"] } }, :status => :not_found
		end		
	end

end