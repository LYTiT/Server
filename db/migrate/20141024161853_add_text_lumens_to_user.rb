class AddTextLumensToUser < ActiveRecord::Migration
  def change
  	add_column :users, :text_lumens, :float, :default => 0.0
    add_index :users, :text_lumens  	
  end
end
