class AddLatestUserPingToInstagramVortexes < ActiveRecord::Migration
  def change
  	add_column :instagram_vortexes, :last_user_ping, :datetime
  end
end
