class AddSpatialColumnsToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :lonlat_geometry, :st_point, :geometry => true
  	add_column :users, :lonlat_geography, :st_point, :geographic => true
  	add_index :users, :lonlat_geometry, using: :gist
  	add_index :users, :lonlat_geography, using: :gist  	
  end
end
