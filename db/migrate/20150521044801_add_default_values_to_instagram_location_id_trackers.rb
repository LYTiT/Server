class AddDefaultValuesToInstagramLocationIdTrackers < ActiveRecord::Migration
  def up
  	change_column :instagram_location_id_trackers, :primary_instagram_location_id_miss_count, :integer, :default => 0
  	change_column :instagram_location_id_trackers, :secondary_instagram_location_id_miss_count, :integer, :default => 0
  	change_column :instagram_location_id_trackers, :tertiary_instagram_location_id_miss_count, :integer, :default => 0

  	change_column :instagram_location_id_trackers, :primary_instagram_location_id_pings, :integer, :default => 0
  	change_column :instagram_location_id_trackers, :secondary_instagram_location_id_pings, :integer, :default => 0
  	change_column :instagram_location_id_trackers, :tertiary_instagram_location_id_pings, :integer, :default => 0
  end

  def down
  	change_column :instagram_location_id_trackers, :primary_instagram_location_id_miss_count, :integer, :default => nil
  	change_column :instagram_location_id_trackers, :secondary_instagram_location_id_miss_count, :integer, :default => nil
  	change_column :instagram_location_id_trackers, :tertiary_instagram_location_id_miss_count, :integer, :default => nil

  	change_column :instagram_location_id_trackers, :primary_instagram_location_id_pings, :integer, :default => nil
  	change_column :instagram_location_id_trackers, :secondary_instagram_location_id_pings, :integer, :default => nil
  	change_column :instagram_location_id_trackers, :tertiary_instagram_location_id_pings, :integer, :default => nil
  end
end
