class AddVenueCommentToFeedMessages < ActiveRecord::Migration
  def change
  	add_column :feed_messages, :venue_comment_id, :integer
  end
end
