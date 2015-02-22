class FixVenueColumnName < ActiveRecord::Migration
  def change
  	rename_column :venues, :lyt_sphere, :l_sphere
  end
end
