class RemoveGooglePlaceKeyFromVenues < ActiveRecord::Migration
  def change
    remove_column :venues, :google_place_key, :text
  end
end
