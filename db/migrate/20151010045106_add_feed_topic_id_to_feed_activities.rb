class AddFeedTopicIdToFeedActivities < ActiveRecord::Migration
  def change
  	add_column :feed_activities, :feed_topic_id, :integer
  end
end
