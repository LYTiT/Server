class Event < ActiveRecord::Base

  attr_accessor :address, :city, :state, :postal_code, :formatted_address

  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :user_id, presence: true

  validate :location_or_venue_present, :atleast_one_group_required

  has_many :events_groups
  has_many :groups, :through => :events_groups

  belongs_to :venue

  accepts_nested_attributes_for :events_groups

  after_create :add_gps_venue, :send_notification_to_group

  def location_or_venue_present
    if self.venue_id.blank? and self.location_name.blank?
      errors.add(:location, 'has to be picked for the event or add a venue')
    end
  end

  def atleast_one_group_required
    if self.events_groups.length == 0
      errors.add(:group, 'is required')
    end
  end

  def expiration_check
    if self.end_date < Time.now
      return 1
    else
      return 0
    end
  end

  def add_gps_venue
    return if self.venue_id.present?
    v = Venue.new
    v.name = self.location_name
    v.latitude = self.latitude
    v.longitude = self.longitude
    v.address = self.address
    v.city = self.city
    v.state = self.state
    v.postal_code = self.postal_code
    v.formatted_address = self.formatted_address
    v.start_date = self.start_date
    v.end_date = self.end_date
    v.save
    self.update(venue_id: v.id)
  end

  def send_notification_to_group
    users_ids = []
    for group in self.groups
      for user in group.users
        next if !user.send_event_added_to_group_notification?(group)
        users_ids.push(user.id)
      end
    end
    group.delay.send_notification_to_users(users_ids.uniq, self.id)
  end

  def user_groups(user)
    groups.joins(:groups_users).where(:groups_users => {:user_id => user.id})
  end

end
