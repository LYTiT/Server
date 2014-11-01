class DropGeolookup < ActiveRecord::Migration
  def change
  	drop_table :geolookups
  end
end
