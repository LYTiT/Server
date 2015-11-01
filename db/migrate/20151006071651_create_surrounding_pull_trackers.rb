class CreateSurroundingPullTrackers < ActiveRecord::Migration
  def change
    create_table :surrounding_pull_trackers do |t|
	   	t.references :user, index: true
	  	t.datetime :latest_pull_time
	  	t.float :latitude, index: true
	  	t.float :longitude, index: true
	  	t.timestamps
    end
  end
end
