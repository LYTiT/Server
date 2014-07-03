class AddGooglePlaceKeyIndexToVenues < ActiveRecord::Migration
  def change
    add_index :venues, :google_place_key, unique: true
  end
end
