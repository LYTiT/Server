class CreateFeedActivities < ActiveRecord::Migration
  def change
    create_table :feed_activities do |t|
    	t.references :feed, index: true
    	t.string :activity_type
    	t.references :venue_comment
    	t.references :feed_message
    	t.references :feed_venue
    	t.references :feed_user
    	t.references :like
    	t.references :feed_recommendation
    	t.integer :adjusted_sort_position, :limit => 5

    	t.timestamps
    end
    add_index :feed_activities, :adjusted_sort_position
  end
end
