class AtGroupRelationship < ActiveRecord::Base
 belongs_to :venue_comment
 belongs_to :group
 validates :venue_comment_id, presence: true
 validates :group_id, presence: true

 after_create :at_group_notification

 def at_group_notification
   self.delay.send_at_group_notification
 end

 def send_at_group_notification
   for user in self.group.users.to_a
   
     next if user.id == self.user_id or !user.send_location_added_to_group_notification?(self.group)
     next if user.version_compatible?("3.2.0") == false
     
     payload = { 
       :object_id => self.id, 
       :type => 'at_group', 
       :group_id => self.group.id,
       :venue_comment_id => self.venue_comment.id, 
       :user_id => user.id
     }
     message = "A Moment @#{self.group.name} has been mapped"
     notification = self.store_notification(payload, user, message)
     payload[:notification_id] = notification.id

     if user.push_token
       count = Notification.where(user_id: user.id, read: false).count
       APNS.delay.send_notification(user.push_token, { :priority =>10, :alert => message, :content_available => 1, :other => payload, :badge => count})
     end

     if user.gcm_token
       gcm_payload = payload.dup
       gcm_payload[:message] = message
       options = {
         :data => gcm_payload
       }
       request = HiGCM::Sender.new(ENV['GCM_API_KEY'])
       request.send([user.gcm_token], options)
     end

   end
 end

 def store_notification(payload, user, message)
   notification = {
     :payload => payload,
     :gcm => user.gcm_token.present?,
     :apns => user.push_token.present?,
     :response => self.notification_payload(user),
     :user_id => user.id,
     :read => false,
     :message => message,
     :deleted => false
   }
   Notification.create(notification)
 end

 def notification_payload(user)
   {
     :venue_comment => {
       :id => self.venue_comment.id,
       :comment => self.venue_comment.comment,
       :media_type => self.venue_comment.media_type,
       :media_url => self.venue_comment.media_url,
       :user_id => self.venue_comment.user_id,
       :venue_id => self.venue_comment.venue_id,
       :created_at => self.venue_comment.created_at.utc,
       :updated_at => self.venue_comment.updated_at.utc,
     },
     :group => {
       :id => self.group.id,
       :name => self.group.name,
       :description => self.group.description,
       :can_link_events => self.group.can_link_events,
       :can_link_venues => self.group.can_link_venues,
       :is_public => self.group.is_public,
       :created_at => self.group.created_at.utc,
       :updated_at => self.group.updated_at.utc,
       :is_group_admin => self.group.is_user_admin?(user.id),
       :send_notification => GroupsUser.send_notification?(self.group.id, user.id)
     }
   }
 end

end