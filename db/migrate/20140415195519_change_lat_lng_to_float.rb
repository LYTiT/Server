class ChangeLatLngToFloat < ActiveRecord::Migration
  def change
    remove_column :venues, :latitude
    remove_column :venues, :longitude

    Venue.reset_column_information

    add_column :venues, :latitude, :float
    add_column :venues, :longitude, :float
  end
end
