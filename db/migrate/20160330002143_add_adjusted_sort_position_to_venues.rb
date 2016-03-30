class AddAdjustedSortPositionToVenues < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :adjusted_sort_position, :integer, :default => 0, :index => true
  end
end
