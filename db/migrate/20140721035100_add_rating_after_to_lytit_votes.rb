class AddRatingAfterToLytitVotes < ActiveRecord::Migration
  def change
    add_column :lytit_votes, :rating_after, :float
  end
end
