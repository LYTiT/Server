class CleanupVenueIndices2 < ActiveRecord::Migration
  def change
  	#remove_index(:venues, :name => 'index_venues_on_user_id')
  	remove_index(:venues, :name => 'index_venues_on_event_id')
  end
end
