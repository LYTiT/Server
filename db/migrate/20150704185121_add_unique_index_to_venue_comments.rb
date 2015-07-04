class AddUniqueIndexToVenueComments < ActiveRecord::Migration
  def change
  	add_index "venue_comments", ["id", "instagram_id"], :unique => true
  end
end
