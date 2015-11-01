class DropInstagramLocationIdTrackers < ActiveRecord::Migration
  def change
  	drop_table :instagram_location_id_trackers
  end
end
