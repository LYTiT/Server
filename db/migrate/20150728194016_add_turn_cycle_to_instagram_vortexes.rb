class AddTurnCycleToInstagramVortexes < ActiveRecord::Migration
  def change
  	add_column :instagram_vortexes, :turn_cycle, :integer
  end
end
