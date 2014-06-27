class AddColorRatingToVenues < ActiveRecord::Migration
  def change
    add_column :venues, :color_rating, :float
  end
end
