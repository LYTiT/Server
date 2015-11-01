class CreateInstagramVortexes < ActiveRecord::Migration
  def change
    create_table :instagram_vortexes do |t|
    	t.float :latitude
    	t.float :longitude
    	t.datetime :last_instagram_pull_time
    	t.string :city
    	t.float :pull_radius
    end
  end
end
