class FixUniqueIndices < ActiveRecord::Migration
  def change
  	remove_index(:feed_users, :name => 'index_feed_users_on_id_and_user_id')
  	remove_index(:feed_venues, :name => 'index_feed_venues_on_id_and_venue_id')
  	add_index "feed_users", ["feed_id", "user_id"], :unique => true
  	add_index "feed_venues", ["feed_id", "venue_id"], :unique => true
  end
end
