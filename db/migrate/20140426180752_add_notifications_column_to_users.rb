class AddNotificationsColumnToUsers < ActiveRecord::Migration
  def change
    add_column :users, :notify_location_added_to_groups, :boolean, default: false
    add_column :users, :notify_events_added_to_groups, :boolean, default: false
  end
end
