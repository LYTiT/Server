class AddImageLumensToUser < ActiveRecord::Migration
  def change
  	add_column :users, :image_lumens, :float, :default => 0.0
    add_index :users, :image_lumens
  end
end
