class AddMovementDirectionToInstagramVortexes < ActiveRecord::Migration
  def change
  	add_column :instagram_vortexes, :movement_direction, :integer
  end
end
