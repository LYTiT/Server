class AddFeedDetailsToFeedVenues < ActiveRecord::Migration
  def change
  	add_column :feed_venues, :feed_details, :json, default: {}
  end
end
