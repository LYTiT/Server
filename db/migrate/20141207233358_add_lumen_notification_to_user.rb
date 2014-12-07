class AddLumenNotificationToUser < ActiveRecord::Migration
  def change
    add_column :users, :lumen_notification, :float, :default => 0.0
  end
end
