class GroupsVenue < ActiveRecord::Base

  belongs_to :venue
  belongs_to :group

  after_create :send_venue_added_notification

  def send_venue_added_notification
    for user in self.group.users
      token = user.push_token
      if token
        a = APNS.send_notification(token, {:alert => '', :content_available => 1, :other => {:object_id => self.id, :type => 'venue_added', :venue_id => self.venue.id, :group_id => self.group.id}})
      end
    end
  end

end
