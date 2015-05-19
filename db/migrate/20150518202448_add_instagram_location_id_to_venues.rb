class AddInstagramLocationIdToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :instagram_location_id, :integer
  end
end
