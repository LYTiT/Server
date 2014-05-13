class AddUserAddingVenuesToGroupsVenues < ActiveRecord::Migration
  def change
    add_reference :groups_venues, :user, index: true
  end
end
