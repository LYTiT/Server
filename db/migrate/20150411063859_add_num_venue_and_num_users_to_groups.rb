class AddNumVenueAndNumUsersToGroups < ActiveRecord::Migration
  def change
  	add_column :groups, :venues_count, :integer
  	add_column :groups, :users_count, :integer
  end
end
