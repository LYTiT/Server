class AddDefaultValueToVenueComments < ActiveRecord::Migration
  def up
  	change_column :venue_comments, :consider, :integer, :default => 2
  end

  def down
  	change_column :venue_comments, :consider, :integer, :default => nil
  end
end
