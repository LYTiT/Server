class AddBountyLumensToUser < ActiveRecord::Migration
  def change
  	add_column :users, :bounty_lumens, :float, :default => 0.0
  end
end
