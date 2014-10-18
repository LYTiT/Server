class AddLumensToUser < ActiveRecord::Migration
  def change
    add_column :users, :lumens, :float
    add_index :users, :lumens
  end
end
