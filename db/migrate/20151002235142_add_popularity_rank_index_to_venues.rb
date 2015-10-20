class AddPopularityRankIndexToVenues < ActiveRecord::Migration
  def change
  	add_index "venues", ["popularity_rank"]
  end
end
