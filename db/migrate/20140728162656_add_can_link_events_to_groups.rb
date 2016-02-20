class AddCanLinkEventsToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :can_link_events_dupe, :boolean, default: true
  end
end
