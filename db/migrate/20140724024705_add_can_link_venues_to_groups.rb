class AddCanLinkVenuesToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :can_link_venues, :boolean
  end
end
