class CreateVenueRatings < ActiveRecord::Migration
  def change
    create_table :venue_ratings do |t|
      t.references :user, index: true
      t.references :venue, index: true
      t.float :rating
      t.timestamps
    end
  end
end
