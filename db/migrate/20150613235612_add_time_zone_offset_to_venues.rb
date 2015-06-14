class AddTimeZoneOffsetToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :time_zone_offset, :float
  end
end
