class AddGroupToInstagamVortexes < ActiveRecord::Migration
  def change
  	add_column :instagram_vortexes, :group, :integer
  	rename_column :instagram_vortexes, :city_que, :group_que
  end
end
