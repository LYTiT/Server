class AddMissColumnsToInstagramLocationIdTrackers < ActiveRecord::Migration
  def change
  	add_column :instagram_location_id_trackers, :tertiary_instagram_location_id, :string

  	add_column :instagram_location_id_trackers, :primary_instagram_location_id_miss_count, :integer
  	add_column :instagram_location_id_trackers, :secondary_instagram_location_id_miss_count, :integer
  	add_column :instagram_location_id_trackers, :tertiary_instagram_location_id_miss_count, :integer
  end
end
