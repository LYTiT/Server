class AddKeyToVenue < ActiveRecord::Migration
  def change
  	add_column :venues, :key, :bigint
  	add_index :venues, :key
  end
end
