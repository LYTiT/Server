class CreateTempPostingHousings < ActiveRecord::Migration
  def change
    create_table :temp_posting_housings do |t|
      t.string :comment
      t.string :media_type
      t.string :image_url_1
      t.integer :session
      t.boolean :username_private
      t.references :user, index: true
      t.references :venue, index: true

      t.timestamps
    end
  end
end
