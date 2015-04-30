class AddLytSphereToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :lyt_sphere, :string
  	add_index :venues, :lyt_sphere
  end
end
