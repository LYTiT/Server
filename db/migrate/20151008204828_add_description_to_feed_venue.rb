class AddDescriptionToFeedVenue < ActiveRecord::Migration
  def change
  	add_column :feed_venues, :description, :text
  end
end
