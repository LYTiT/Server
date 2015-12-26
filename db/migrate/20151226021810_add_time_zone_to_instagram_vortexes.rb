class AddTimeZoneToInstagramVortexes < ActiveRecord::Migration
  def change
  	add_column :instagram_vortexes, :time_zone_offset, :float
  end
end
