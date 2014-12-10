class Group < ActiveRecord::Base
  acts_as_paranoid
#Checks if the Group name is not too long or already taken
  validates_length_of :name, :within => 1..30
  validates_uniqueness_of :name, :message => "Name already exists"

  validates :name, presence: true
  validates_uniqueness_of :name, case_sensitive: false

  validates_inclusion_of :is_public, in: [true, false]
  validates :password, presence: true, :if => :should_validate_password?

  validates_inclusion_of :can_link_events, in: [true, false]
  
  validates_inclusion_of :can_link_venues, in: [true, false]

  has_many :group_invitations, foreign_key: "igroup_id", dependent: :destroy
  has_many :invitations, through: :group_invitations, source: :invited

  has_many :groups_users
  has_many :users, through: :groups_users

  has_many :groups_venues
  has_many :venues, through: :groups_venues

  has_many :events_groups
  has_many :events, through: :events_groups

  def should_validate_password?
  	not is_public
  end
  
  # def can_link_event?
  #   can_link_event
  #end

  def join(user_id, pwd)
    if !self.is_public? and self.password != pwd
      return false, 'Verification password failed'
    end

    if !self.is_user_member?(user_id)
      # do nothing if user is already a member
      GroupsUser.create(group_id: self.id, user_id: user_id)
    end
    true
  end

  def remove(user_id)
    GroupsUser.where("group_id = ? and user_id = ?", self.id, user_id).destroy_all
  end

  def is_user_admin?(user_id)
    GroupsUser.where("group_id = ? and user_id = ?", self.id, user_id).first.try(:is_admin) ? true : false
  end

  def is_user_member?(user_id)
    GroupsUser.where("group_id = ? and user_id = ?", self.id, user_id).first ? true : false
  end

  #invite a user to join the group. Need to declare a host.
  def invite_to_join(invitee_id, inviter_id)
    group_invitations.create!(igroup_id: self.id, invited_id: invitee_id, host_id: inviter_id)
  end

  def return_password_if_admin(user_id)
    self.is_user_admin?(user_id) ? self.password : nil
  end

  def toggle_user_admin(user_id, approval)
    group_user = GroupsUser.where("group_id = ? and user_id = ?", self.id, user_id).first
    group_user.update(:is_admin => (approval == 'yes' ? true : false))
  end

  def add_venue(venue_id, user_id)
    if self.is_user_member?(user_id)
      GroupsVenue.create(group_id: self.id, venue_id: venue_id, user_id: user_id)
      return true
    else
      return false, 'You are not member of this group'
    end
  end

  def remove_venue(venue_id, user_id)
    GroupsVenue.where("group_id = ? and venue_id = ?", self.id, venue_id).destroy_all
    return true
  end

  def venues_with_user_who_added
    venues = self.venues.order("venues.name ASC").as_json
    for venue in venues
      gv = GroupsVenue.where("group_id = ? and venue_id = ?", self.id, venue["id"]).first
      info = gv.as_json.slice("created_at", "user_id")
      user = User.find(info["user_id"])
      venue.update({"venue_added_at" => info["created_at"], "user_adding_venue" => user.name})
    end
    venues
  end

  def send_notification_to_users(user_ids, event_id)
    event = Event.find(event_id)
    for user_id in user_ids
      user = User.find(user_id)
      groups = event.user_groups(user)
      group_names = groups.collect(&:name)
      payload = {
        :object_id => event_id, 
        :type => 'event_added', 
        :user_id => user_id
      }
      message = "New event posted to #{group_names.join(", ")}"
      notification = self.store_notification(payload, user, event_id, message)
      payload[:notification_id] = notification.id

      if user.push_token
        count = Notification.where(user_id: user.id, read: false).count
        APNS.delay.send_notification(user.push_token, {:priority =>10, :alert => message, :content_available => 1, :other => payload, :badge => count})
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

  def store_notification(payload, user, event_id, message)
    @event = Event.find_by_id(event_id)
    event = @event.as_json(:include => [:venue])
    event["created_at"] = event["created_at"].utc rescue nil
    event["updated_at"] = event["updated_at"].utc rescue nil
    event["start_date"] = event["start_date"].utc rescue nil
    event["end_date"] = event["end_date"].utc rescue nil
    event["venue"]["created_at"] = event["venue"]["created_at"].utc rescue nil
    event["venue"]["updated_at"] = event["venue"]["updated_at"].utc rescue nil
    event["venue"]["fetched_at"] = event["venue"]["fetched_at"].utc rescue nil
    event["venue"]["start_date"] = event["venue"]["start_date"].utc rescue nil
    event["venue"]["end_date"] = event["venue"]["end_date"].utc rescue nil
    event["groups"] = @event.user_groups(user)
    event["groups"] = event["groups"].as_json
    event["groups"].each do |group|
      group["created_at"] = group["created_at"].utc rescue nil
      group["updated_at"] = group["updated_at"].utc rescue nil
      group["deleted_at"] = group["deleted_at"].utc rescue nil
    end
    notification = {
      :payload => payload,
      :gcm => user.gcm_token.present?,
      :apns => user.push_token.present?,
      :response => event,
      :user_id => user.id,
      :read => false,
      :message => message,
      :deleted => false
    }
    Notification.create(notification)
  end

end
