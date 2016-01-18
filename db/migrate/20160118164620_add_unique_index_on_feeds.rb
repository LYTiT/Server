class AddUniqueIndexOnFeeds < ActiveRecord::Migration
  def change
  	add_index "feeds", ["name", "user_id"], :unique => true
  end
end
