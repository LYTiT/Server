class AddBountyIndexToVenueComments < ActiveRecord::Migration
  def change
  	add_index :venue_comments, :bounty_id
  end
end
