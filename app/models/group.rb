class Group < ActiveRecord::Base
  validates :name, presence: true  
  validates_inclusion_of :is_public, in: [true, false]
  validates :password, presence: true, :if => :should_validate_password?
  validates :user, presence: true
  validates :venue, presence: true

  belongs_to :user # group admin
  belongs_to :venue
  
  after_create :add_creator_as_member
  
  def should_validate_password?
  	not is_public
  end
  
  def add_creator_as_member
    GroupsUser.create(group_id: self.id, user_id: self.user_id, is_admin: true)
  end
  
  def join(user_id, pwd)
    if !self.is_public? and self.password != pwd
      return false, 'Verification password failed'
    end
    GroupsUser.create(group_id: self.id, user_id: user_id)
    true
  end
  
  def leave(user_id)
    GroupsUser.where(group_id: self.id, user_id: user_id).destroy
  end
  
end
