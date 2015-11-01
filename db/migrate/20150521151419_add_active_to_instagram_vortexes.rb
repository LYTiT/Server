class AddActiveToInstagramVortexes < ActiveRecord::Migration
  def change
  	add_column :instagram_vortexes, :active, :boolean
  	add_column :instagram_vortexes, :description, :string
  end
end
