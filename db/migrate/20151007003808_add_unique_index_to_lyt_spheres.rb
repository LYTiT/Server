class AddUniqueIndexToLytSpheres < ActiveRecord::Migration
  def change
  	add_index "lyt_spheres", ["id", "venue_id"], :unique => true
  end
end
