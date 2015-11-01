class AddUniqueIndicesToFeedUsersAndVenues < ActiveRecord::Migration
  def change
  	add_index "feed_users", ["id", "user_id"], :unique => true
  	add_index "feed_venues", ["id", "venue_id"], :unique => true
  end
end
