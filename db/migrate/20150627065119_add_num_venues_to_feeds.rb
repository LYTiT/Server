class AddNumVenuesToFeeds < ActiveRecord::Migration
  def change
  	add_column :venues, :num_venues, :integer, :default => 0
  end
end
