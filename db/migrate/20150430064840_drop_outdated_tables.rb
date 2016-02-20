class DropOutdatedTables < ActiveRecord::Migration
  def change
  	#drop_table :events
  	drop_table :events_groups
  	drop_table :flagged_events
  	drop_table :flagged_groups
  	drop_table :groups
  	drop_table :group_invitations
  	drop_table :groups_users
  	drop_table :groups_venues
  	drop_table :groups_venue_comments
  	drop_table :relationships
  	drop_table :venue_relationships
  end
end
