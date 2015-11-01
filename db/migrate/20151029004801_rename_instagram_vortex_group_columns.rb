class RenameInstagramVortexGroupColumns < ActiveRecord::Migration
  def change
  	rename_column :instagram_vortexes, :group, :vortex_group
  	rename_column :instagram_vortexes, :group_que, :vortex_group_que
  end
end
