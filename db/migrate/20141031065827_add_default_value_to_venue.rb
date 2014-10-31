class AddDefaultValueToVenue < ActiveRecord::Migration
  def up
  	change_column :venues, :r_up_votes, :float, :default => 1.0
  	change_column :venues, :r_down_votes, :float, :default => 1.0
  end

  def down
  	change_column :venues, :r_up_votes, :float, :default => nil
  	change_column :venues, :r_down_votes, :float, :default => nil
  end
end
