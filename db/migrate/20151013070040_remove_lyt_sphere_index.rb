class RemoveLytSphereIndex < ActiveRecord::Migration
  def change
  	remove_index :lyt_spheres, [:id, :venue_id]
  end
end
