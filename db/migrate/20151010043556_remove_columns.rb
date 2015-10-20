class RemoveColumns < ActiveRecord::Migration
  def change
  	remove_column :feed_activities, :feed_message_id, :integer
  	remove_column :likes, :feed_message_id, :integer
  	remove_column :feed_venues, :num_likes, :integer
  	remove_column :feed_activities, :like_id, :integer
  	remove_column :likes, :feed_venue_id, :integer
  	remove_column :likes, :type, :string
  end
end
