class AddInstagramVortexIdToVenues < ActiveRecord::Migration
  def change
  	add_column(:venues, :instagram_vortex_id, :integer)
  end
end
