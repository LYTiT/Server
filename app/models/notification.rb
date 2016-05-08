class Notification
  
  include MongoMapper::Document

  timestamps!
  safe 

  def Notification.bulk_destroy(notification_ids)
	for notification_id in notification_ids
		notification = Notification.where(id: notification_id, deleted: false).first
		notification[:deleted] = true
		notification.save
	end
  end

end