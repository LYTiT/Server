class AddTimeZoneToVortices < ActiveRecord::Migration
  def change
  	add_column(:instagram_vortexes, :time_zone, :string)
  end
end
