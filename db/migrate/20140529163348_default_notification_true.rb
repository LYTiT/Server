class DefaultNotificationTrue < ActiveRecord::Migration

  def up
    change_column :users, :notify_location_added_to_groups, :boolean, default: true
    change_column :users, :notify_events_added_to_groups, :boolean, default: true
  end

  def down
    change_column :users, :notify_location_added_to_groups, :boolean, default: false
    change_column :users, :notify_events_added_to_groups, :boolean, default: false
  end

end
