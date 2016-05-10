class AddActivityIdsToFeedVenues < ActiveRecord::Migration
  def change
  	add_column :feed_venues, :activity_id, :integer
  end
end
