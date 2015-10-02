class AddColorIndexToVenues < ActiveRecord::Migration
  def change
  	add_index "venues", ["color_rating"]
  end
end
