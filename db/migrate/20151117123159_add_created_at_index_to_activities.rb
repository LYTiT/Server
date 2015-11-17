class AddCreatedAtIndexToActivities < ActiveRecord::Migration
  def change
  	add_index "activities", "created_at", :unique => true
  end
end
