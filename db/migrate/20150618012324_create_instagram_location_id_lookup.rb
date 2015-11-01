class CreateInstagramLocationIdLookup < ActiveRecord::Migration
  def change
    create_table :instagram_location_id_lookups do |t|
    	t.references :venue, index: true
    	t.string :instagram_location_id
    end
    add_index :instagram_location_id_lookups, :instagram_location_id
  end
end
