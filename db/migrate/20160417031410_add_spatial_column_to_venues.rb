class AddSpatialColumnToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :lonlat_geometry, :st_point, :geometry => true
  	add_column :venues, :lonlat_geography, :st_point, :geographic => true
  	add_index :venues, :lonlat_geometry, using: :gist
  	add_index :venues, :lonlat_geography, using: :gist
  end
end
