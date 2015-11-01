class AlterColorRatingInVenues < ActiveRecord::Migration
  def change
    change_column :venues, :color_rating, :float, :default => -1.0
  end
end
