class AddNumVenuesToFeeds < ActiveRecord::Migration
  def change
  	add_column :feeds, :num_venues, :integer, :default => 0
  end
end
