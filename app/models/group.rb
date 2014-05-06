class Group < ActiveRecord::Base
  validates :name, presence: true  
  validates_inclusion_of :is_public, in: [true, false]
  validates :password, presence: true, :if => :should_validate_password?

  has_many :groups_users
  has_many :users, through: :groups_users
  
  has_many :groups_venues
  has_many :venues, through: :groups_venues
  
  def should_validate_password?
  	not is_public
  end
  
  def join(user_id, pwd)
    if !self.is_public? and self.password != pwd
      return false, 'Verification password failed'
    end
    GroupsUser.create(group_id: self.id, user_id: user_id)
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
  
  def toggle_user_admin(user_id, approval)
    group_user = GroupsUser.where("group_id = ? and user_id = ?", self.id, user_id).first
    group_user.update(:is_admin => (approval == 'yes' ? true : false))
  end
  
  def add_venue(venue_id, user_id)
    if self.is_user_member?(user_id)
      GroupsVenue.create(group_id: self.id, venue_id: venue_id)
      return true
    else
      return false, 'You are not member of this group'
    end  
  end
  
  def remove_venue(venue_id, user_id)
    if self.is_user_member?(user_id)
      GroupsVenue.where("group_id = ? and venue_id = ?", self.id, venue_id).destroy_all
      return true
    else
      return false, 'You are not member of this group'
    end  
  end
  
end
