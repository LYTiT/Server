class GroupsVenue < ActiveRecord::Base

  belongs_to :venue
  belongs_to :group

  after_create :send_venue_added_notification

  def send_venue_added_notification
    for user in self.group.users
    
      next if user.id == self.user_id or !user.send_location_added_to_group_notification?(self.group)
      
      payload = { 
        :object_id => self.id, 
        :type => 'venue_added', 
        :venue_id => self.venue.id, 
        :group_id => self.group.id, 
        :user_id => user.id 
      }
      
      if user.push_token
        APNS.delay.send_notification(user.push_token, { :alert => '', :content_available => 1, :other => payload})
      end

      if user.gcm_token
        options = {
          :data => payload
        }
        request = HiGCM::Sender.new(ENV['GCM_API_KEY'])
        request.send([user.gcm_token], options)
      end

    end
  end
end
