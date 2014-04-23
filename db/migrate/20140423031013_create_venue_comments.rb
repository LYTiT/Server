class CreateVenueComments < ActiveRecord::Migration
  def change
    create_table :venue_comments do |t|
      t.string :comment
      t.string :media_type
      t.string :media_url
      t.references :user, index: true
      t.references :venue, index: true

      t.timestamps
    end
  end
end
