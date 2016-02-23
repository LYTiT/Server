class AddTimeStampsToVortices < ActiveRecord::Migration
  def change
  	  	add_column(:instagram_vortexes, :created_at, :datetime)
		add_column(:instagram_vortexes, :updated_at, :datetime)
  end
end
