class AddTsvectorColumnToVenues < ActiveRecord::Migration
  def up
    add_column :venues, :meta_data_vector, :tsvector
    add_index :venues, :meta_data_vector, using: "gin"
  end

  def down
  	remove_index :venues, :meta_data_vector
    remove_column :venues, :meta_data_vector
  end
end
