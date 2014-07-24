class AddCanLinkVenuesToGroups < ActiveRecord::Migration
  def change
    add_column :groups, :can_link_venues, :boolean, default:true
  end
end
