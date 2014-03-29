class CreateVenues < ActiveRecord::Migration
  def change
    create_table :venues do |t|
      t.string :name
      t.string :latitude
      t.string :longitude
      t.integer :rating
      t.string :phone_number
      t.text :address
      t.string :city
      t.string :state

      t.timestamps
    end
  end
end
