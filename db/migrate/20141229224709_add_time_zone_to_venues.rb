class AddTimeZoneToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :time_zone, :string
  end
end
