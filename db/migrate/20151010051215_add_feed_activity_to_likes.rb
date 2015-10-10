class AddFeedActivityToLikes < ActiveRecord::Migration
  def change
  	add_column :likes, :feed_activity_id, :integer
  end
end
