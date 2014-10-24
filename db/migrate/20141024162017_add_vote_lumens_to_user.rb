class AddVoteLumensToUser < ActiveRecord::Migration
  def change
  	add_column :users, :vote_lumens, :float, :default => 0.0
    add_index :users, :vote_lumens   	
  end
end
