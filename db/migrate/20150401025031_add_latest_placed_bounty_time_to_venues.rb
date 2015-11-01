class AddLatestPlacedBountyTimeToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :latest_placed_bounty_time, :datetime
  end
end
