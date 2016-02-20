class AddCanLinkVenuesToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :can_link_venues_dupe, :boolean, default: true
  end
end
