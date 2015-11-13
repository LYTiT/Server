class AddNumLikesToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :num_likes, :integer, :default => 0
  end
end
