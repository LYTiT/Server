class AddTrendPositionToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :trend_position, :integer
  end
end
