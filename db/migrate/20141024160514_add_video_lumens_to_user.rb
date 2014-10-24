class AddVideoLumensToUser < ActiveRecord::Migration
  def change
  	add_column :users, :video_lumens, :float, :default => 0.0
    add_index :users, :video_lumens
  end
end
