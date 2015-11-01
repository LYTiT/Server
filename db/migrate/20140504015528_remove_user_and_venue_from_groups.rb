class RemoveUserAndVenueFromGroups < ActiveRecord::Migration
  def change
  	remove_column :groups, :user_id
  	remove_column :groups, :venue_id
  end
end
