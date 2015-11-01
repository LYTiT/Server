class CreateInstagramLocationIdTrackers < ActiveRecord::Migration
  def change
    create_table :instagram_location_id_trackers do |t|
    	t.references :venue, index: true
    	t.string :primary_instagram_location_id
    	t.string :secondary_instagram_location_id

    	t.integer :primary_instagram_location_id_pings
    	t.integer :secondary_instagram_location_id_pings
    	t.integer :tertiary_instagram_location_id_pings
    end
  end
end
