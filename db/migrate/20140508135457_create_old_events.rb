class CreateOldEvents < ActiveRecord::Migration
  def change
    create_table :old_events do |t|
      t.string :name
      t.text :description
      t.date :start_date
      t.date :end_date
      t.string :start_time
      t.string :end_time
      t.text :location_name
      t.text :latitude
      t.text :longitude
      t.integer :venue_id
      t.integer :user_id
      t.timestamps
    end
  end
end
