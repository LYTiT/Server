class CreateVenueComments < ActiveRecord::Migration
  def change
    create_table :venue_comments do |t|
      t.string :comment
      t.string :media_type
      t.string :image_url_1
      t.references :user, index: true
      t.references :venue, index: true

      t.timestamps
    end
  end
end
