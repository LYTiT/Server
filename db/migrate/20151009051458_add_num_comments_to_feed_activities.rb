class AddNumCommentsToFeedActivities < ActiveRecord::Migration
  def change
  	add_column :feed_activities, :num_comments, :integer, :default => 0
  end
end
