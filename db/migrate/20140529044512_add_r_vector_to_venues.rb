class AddRVectorToVenues < ActiveRecord::Migration
  def change
    add_column :venues, :r_up_votes, :float
    add_column :venues, :r_down_votes, :float
  end
end
