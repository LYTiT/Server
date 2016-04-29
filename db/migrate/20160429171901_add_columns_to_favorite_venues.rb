class AddColumnsToFavoriteVenues < ActiveRecord::Migration
  def change
  	add_column :favorite_venues, :latest_check_time, :datetime

  end
end
