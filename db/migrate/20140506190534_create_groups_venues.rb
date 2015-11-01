class CreateGroupsVenues < ActiveRecord::Migration
  def change
    create_table :groups_venues do |t|
      t.integer :group_id
      t.integer :venue_id
      t.timestamps
    end
  end
end
