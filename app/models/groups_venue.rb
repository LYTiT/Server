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

      # Store Notification History
      notification = {
        :payload => payload,
        :gcm => user.gcm_token.present?,
        :apns => user.push_token.present?,
        :response => self.notification_payload(user),
        :user_id => user.id
      }
      Notification.create(notification)

    end
  end

  def notification_payload(user)
    {
      :venue => {
        :id => self.venue.id,
        :name => self.venue.name,
        :rating => self.venue.rating,
        :phone_number => self.venue.phone_number,
        :address => self.venue.address,
        :city => self.venue.city,
        :state => self.venue.state,
        :created_at => self.venue.created_at,
        :updated_at => self.venue.updated_at,
        :latitude => self.venue.latitude,
        :longitude => self.venue.longitude,
        :google_place_rating => self.venue.google_place_rating,
        :google_place_key => self.venue.google_place_key,
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
        :created_at => self.group.created_at,
        :updated_at => self.group.updated_at,
        :is_group_admin => self.group.is_user_admin?(user.id),
        :send_notification => GroupsUser.send_notification?(self.group.id, user.id)
      }
    }
  end

end
