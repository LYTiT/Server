class AddNotificationFlagToGroupsUsers < ActiveRecord::Migration
  def change
    add_column :groups_users, :notification_flag, :boolean, default: true
  end
end
