class RenameFeedVenueGeoColumns < ActiveRecord::Migration
  def change
  	rename_column :feed_venues, :central_mass_lonlat_geometry, :lonlat_geometry
  	rename_column :feed_venues, :central_mass_lonlat_geography, :lonlat_geography
  end
end
