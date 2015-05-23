class AddInstagramIndexToVenueComments < ActiveRecord::Migration
  def change
  	add_index :venue_comments, :instagram_id, unique: true
  end
end
