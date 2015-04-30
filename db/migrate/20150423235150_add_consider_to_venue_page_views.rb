class AddConsiderToVenuePageViews < ActiveRecord::Migration
  def change
  	add_column :venue_page_views, :consider, :boolean, :default => true
  end
end
