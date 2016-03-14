class AddPopularHoursToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :popular_hours, :json, default: {}, null: false  
  end
end
