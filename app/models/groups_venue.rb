class GroupsVenue < ActiveRecord::Base

  belongs_to :venue
  belongs_to :group

  after_create :venue_added_notification

  def venue_added_notification
    self.delay.send_venue_added_notification
  end

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
      message = "#{self.venue.name} has been linked to your Group #{self.group.name}"
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
      :leon => {
        :id => self.venue.id,
        :name => self.venue.name,
        :rating => self.venue.rating,
        :phone_number => self.venue.phone_number,
        :address => self.venue.address,
        :city => self.venue.city,
        :state => self.venue.state,
        :created_at => self.venue.created_at.utc,
        :updated_at => self.venue.updated_at.utc,
        :latitude => self.venue.latitude,
        :longitude => self.venue.longitude,
        :google_place_rating => self.venue.google_place_rating,
        #:google_place_key => self.venue.google_place_key,
        :country => self.venue.country,
        :postal_code => self.venue.postal_code,
        :formatted_address => self.venue.formatted_address,
        :google_place_reference => self.venue.google_place_reference,
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
      },
      :user => {
        :id => user.id,
        :name => user.name,
      }
    }
  end

end
