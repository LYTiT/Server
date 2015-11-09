class AddGeoColumnsToFeeds < ActiveRecord::Migration
  def change
  	add_column :feeds, :central_mass_latitude, :float, :index => true
  	add_column :feeds, :central_mass_longitude, :float, :index => true
  end
end
