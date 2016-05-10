class AddVenueIdsArrayToFeeds < ActiveRecord::Migration
  def change
  	add_column :feeds, :venue_ids, :json, default: [], null: false
  end
end
