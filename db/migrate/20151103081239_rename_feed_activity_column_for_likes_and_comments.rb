class RenameFeedActivityColumnForLikesAndComments < ActiveRecord::Migration
  def change
  	rename_column :likes, :feed_activity_id, :activity_id
  	rename_column :activity_comments, :feed_activity_id, :activity_id
  end
end
