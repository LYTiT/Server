class AddLastTweeAndInstagramIdsToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :last_tweet_id, :integer, :limit => 8
  	add_column :venues, :last_instagram_id, :string
  end
end
