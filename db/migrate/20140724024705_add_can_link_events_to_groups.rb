class AddCanLinkEventsToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :can_link_events, :boolean, default:true
  end
end
