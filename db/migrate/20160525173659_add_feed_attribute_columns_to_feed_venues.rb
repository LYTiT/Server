class AddFeedAttributeColumnsToFeedVenues < ActiveRecord::Migration
  def change
  	add_column :feed_venues, :num_venues, :integer
  	add_column :feed_venues, :num_users, :integer
  	add_column :feed_venues, :score_primer, :integer, default: 0
  	add_column :feed_venues, :central_mass_lonlat_geometry, :st_point, :geometry => true
  	add_column :feed_venues, :central_mass_lonlat_geography, :st_point, :geographic => true
  	add_index :feed_venues, :central_mass_lonlat_geometry, using: :gist
  	add_index :feed_venues, :central_mass_lonlat_geography, using: :gist  	
  end
end
