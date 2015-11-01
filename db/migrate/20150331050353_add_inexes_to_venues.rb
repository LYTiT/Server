class AddInexesToVenues < ActiveRecord::Migration
  def change
  	add_index :venues, :latitude
  	add_index :venues, :longitude
  end
end
