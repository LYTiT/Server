class AddVenueIdIndexToLytSpheres < ActiveRecord::Migration
  def change
  	add_index "lyt_spheres", ["venue_id"], :unique => true
  end
end
