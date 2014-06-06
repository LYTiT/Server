class CreateVenueMessages < ActiveRecord::Migration
  def change
    create_table :venue_messages do |t|
      t.string :message
      t.references :venue, index: true
      t.integer :position

      t.timestamps
    end
  end
end
