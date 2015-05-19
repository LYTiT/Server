class AddInstIdIndexToVenues < ActiveRecord::Migration
  def change
  	add_index :venues, :instagram_location_id
  end
end
