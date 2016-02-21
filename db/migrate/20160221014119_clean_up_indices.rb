class CleanUpIndices < ActiveRecord::Migration
  def change
  	remove_index(:venues, :name => 'index_venues_on_l_sphere')
  	remove_index(:venues, :name => 'index_venues_on_key')
  	remove_index(:lytit_votes, :name => 'index_lytit_votes_on_user_id')
  end
end
