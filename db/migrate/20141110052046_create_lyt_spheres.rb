class CreateLytSpheres < ActiveRecord::Migration
  def change
    create_table :lyt_spheres do |t|
      t.integer :venue_id
      t.string :sphere
      t.timestamps
    end
    add_index :lyt_spheres, :sphere
  end
end