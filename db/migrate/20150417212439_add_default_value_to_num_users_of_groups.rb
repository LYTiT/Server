class AddDefaultValueToNumUsersOfGroups < ActiveRecord::Migration
  def change
  	add_column :groups, :users_count, :integer, :default => 1
  end
end
