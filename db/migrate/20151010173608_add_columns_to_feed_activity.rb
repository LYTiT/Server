class AddColumnsToFeedActivity < ActiveRecord::Migration
  def change
  	add_column :feed_activities, :user_id, :integer
  	add_column :feed_activities, :venue_id, :integer
  end
end
