class DropFeedSharesAndFeedTopics < ActiveRecord::Migration
  def change
  	drop_table :feed_shares
  	drop_table :feed_topics
  	remove_column :activities, :feed_share_id, :integer
  	remove_column :activities, :feed_topic_id, :integer
  end
end
