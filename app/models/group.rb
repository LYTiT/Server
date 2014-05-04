class Group < ActiveRecord::Base
  validates :name, presence: true  
  validates_inclusion_of :is_public, in: [true, false]
  validates :password, presence: true, :if => :should_validate_password?
  #validates :user, presence: true
  #validates :venue, presence: true

  has_many :users, through: :groups_users
  
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
  
  def remove(user_id)
    GroupsUser.where("group_id = ? and user_id = ?", self.id, user_id).destroy_all
  end
  
  def is_user_admin?(user_id)
    GroupsUser.where("group_id = ? and user_id = ?", self.id, user_id).first.try(:is_admin) ? true : false
  end
  
  def toggle_user_admin(user_id, approval)
    group_user = GroupsUser.where("group_id = ? and user_id = ?", self.id, user_id).first
    group_user.update(:is_admin => (approval == 'yes' ? true : false))
  end
  
end
