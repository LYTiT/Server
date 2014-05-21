class AddRatingVectorsToVenues < ActiveRecord::Migration
  def change
    add_column :venues, :v_up_votes, :integer
    add_column :venues, :v_down_votes, :integer
    add_column :venues, :t_minutes_since_last_up_vote, :float
    add_column :venues, :t_minutes_since_last_down_vote, :float
    add_column :venues, :r_up_votes_plus_k, :float
    add_column :venues, :r_down_votes, :float
  end
end
