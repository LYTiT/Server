class AddVoteIdToLumenValues < ActiveRecord::Migration
  def change
  	add_column :lumen_values, :vote_id, :integer
  end
end
