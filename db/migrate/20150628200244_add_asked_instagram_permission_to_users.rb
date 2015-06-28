class AddAskedInstagramPermissionToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :asked_instagram_permission, :boolean, :default => false
  end
end
