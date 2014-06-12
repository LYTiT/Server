class GroupsUser < ActiveRecord::Base

  belongs_to :user
  belongs_to :group

  def self.send_notification?(group_id, user_id)
    GroupsUser.where("group_id = ? and user_id = ?", group_id, user_id).first.try(:notification_flag) ? true : false
  end

end
