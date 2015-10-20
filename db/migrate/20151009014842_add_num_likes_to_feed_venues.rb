class AddNumLikesToFeedVenues < ActiveRecord::Migration
  def change
  	add_column :feed_venues, :num_likes, :integer
  end
end
