class CreateClusterTrackers < ActiveRecord::Migration
  def change
    create_table :cluster_trackers do |t|
    	t.float :latitude
    	t.float :longitude
    	t.float :zoom_level
    	t.integer :num_venues
        t.datetime :last_twitter_pull_time

    	t.timestamps    	
    end    
    add_index :cluster_trackers, :latitude
    add_index :cluster_trackers, :longitude
    add_index :cluster_trackers, :zoom_level
  end
end
