class CreateVortexPaths < ActiveRecord::Migration
  def change
    create_table :vortex_paths do |t|
    	t.references :instagram_vortex, index: true
    	t.float :origin_lat
    	t.float :origin_long
    	t.float :span
    	t.float :increment_distance
    end
  end
end
