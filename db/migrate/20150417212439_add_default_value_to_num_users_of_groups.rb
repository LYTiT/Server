class AddDefaultValueToNumUsersOfGroups < ActiveRecord::Migration
  def up
  	change_column :groups, :users_count, :integer, :default => 1
  end

  def down
  	change_column :groups, :users_count, :integer, :default => nil
  end
end
