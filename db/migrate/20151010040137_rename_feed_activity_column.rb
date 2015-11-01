class RenameFeedActivityColumn < ActiveRecord::Migration
  def change
  	rename_column :feed_activities, :venue_comment_id, :feed_share_id
  end
end
