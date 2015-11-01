class AddCountryToInstgaramVortexes < ActiveRecord::Migration
  def change
  	add_column :instagram_vortexes, :country, :string
  end
end
