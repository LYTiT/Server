class AddBountyIdToVenueComments < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :bounty_id, :integer
  end
end
