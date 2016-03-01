class AddHoursToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :open_hours, :json, default: {}, null: false  
  end
end
