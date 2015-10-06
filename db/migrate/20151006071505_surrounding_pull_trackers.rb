class SurroundingPullTrackers < ActiveRecord::Migration
  def change
  	t.references :user, index: true
  	t.datetime :latest_pull_time
  	t.float :latitude, index: true
  	t.float :longitude, index: true
  	t.timestamps
  end
end
