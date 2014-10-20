class AddDefaultValueToUser < ActiveRecord::Migration
  def up
  	change_column :users, :lumens, :float, :default => 0
  end

  def down
  	change_column :users, :lumens, :float, :default => nil
  end
end
