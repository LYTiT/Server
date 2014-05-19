class Event < ActiveRecord::Base

  validates :name, presence: true
  validates :description, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :user_id, presence: true

  validate :location_or_venue_present, :atleast_one_group_required

  has_many :events_groups
  has_many :groups, :through => :events_groups

  belongs_to :venue

  accepts_nested_attributes_for :events_groups

  after_create :send_notification_to_group

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

  def send_notification_to_group
    for group in self.groups
      group.send_notification_to_users(self.id)
    end
  end

end
