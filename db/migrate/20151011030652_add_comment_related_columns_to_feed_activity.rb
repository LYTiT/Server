class AddCommentRelatedColumnsToFeedActivity < ActiveRecord::Migration
  def change
  	add_column :feed_activities, :latest_comment_time, :datetime
  	add_column :feed_activities, :num_participants, :integer, :default => 0
  end
end
