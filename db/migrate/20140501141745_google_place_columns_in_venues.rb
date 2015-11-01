class GooglePlaceColumnsInVenues < ActiveRecord::Migration
  def change
    add_column :venues, :google_place_rating, :float
    add_column :venues, :google_place_key, :string
  end
end
