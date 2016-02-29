class AddHoursToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :open_hours, :hstore, default: {}, null: false
  end
end
