class AddNumMomentsToFeed < ActiveRecord::Migration
  def change
  	add_column(:feeds, :num_moments, :integer, :default => 0)
  end
end
