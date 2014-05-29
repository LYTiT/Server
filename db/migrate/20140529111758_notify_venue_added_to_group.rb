class NotifyVenueAddedToGroup < ActiveRecord::Migration
  def change
    add_column :users, :notify_venue_added_to_groups, :boolean, :default => true
  end
end
