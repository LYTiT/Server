class AddColumnsToFeedVenues < ActiveRecord::Migration
  def change
  	add_column :feed_venues, :num_upvotes, :integer, :default => 0
  	add_column :feed_venues, :num_comments, :integer, :default => 0
  	add_column :feed_venues, :upvote_user_ids, :json, default: [], null: false
  end
end
