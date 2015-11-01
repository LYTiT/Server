class RenameInstagramVortexColumn < ActiveRecord::Migration
  def change
  	rename_column :instagram_vortexes, :description, :details
  end
end
