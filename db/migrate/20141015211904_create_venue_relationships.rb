class CreateVenueRelationships < ActiveRecord::Migration
  def change
    create_table :venue_relationships do |t|
      t.integer :ufollower_id
      t.integer :vfollowed_id

      t.timestamps
    end
    add_index :venue_relationships, :ufollower_id
    add_index :venue_relationships, :vfollowed_id
    add_index :venue_relationships, [:ufollower_id, :vfollowed_id], unique: true
  end
end
