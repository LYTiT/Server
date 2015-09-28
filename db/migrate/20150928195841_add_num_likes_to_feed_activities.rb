class AddNumLikesToFeedActivities < ActiveRecord::Migration
  def change
  	add_column :feed_activities, :num_likes, :integer, :default => 0
  end
end
