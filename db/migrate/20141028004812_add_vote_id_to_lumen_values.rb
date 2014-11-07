class AddVoteIdToLumenValues < ActiveRecord::Migration
  def change
  	add_column :lumen_values, :lytit_vote_id, :integer
  end
end
