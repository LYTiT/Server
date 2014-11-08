class FixLumenColumnVote < ActiveRecord::Migration
  def change
  	rename_column :lumen_values, :vote_id, :lytit_vote_id
  end
end
