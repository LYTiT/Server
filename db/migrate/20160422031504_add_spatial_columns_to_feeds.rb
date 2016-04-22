class AddSpatialColumnsToFeeds < ActiveRecord::Migration
  def change
  	add_column :feeds, :central_mass_lonlat_geometry, :st_point, :geometry => true
  	add_column :feeds, :central_mass_lonlat_geography, :st_point, :geographic => true
  	add_index :feeds, :central_mass_lonlat_geometry, using: :gist
  	add_index :feeds, :central_mass_lonlat_geography, using: :gist  	
  end
end
