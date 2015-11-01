class AddCityQueToInstagramVortexes < ActiveRecord::Migration
  def change
  	add_column :instagram_vortexes, :city_que, :integer
  end
end
