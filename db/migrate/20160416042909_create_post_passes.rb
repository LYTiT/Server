class CreatePostPasses < ActiveRecord::Migration
  def change
    create_table :post_passes do |t|
    	t.references :user, index: true
    	t.references :venue_comment
    	t.boolean :passed_on
    	t.boolean :reported, default: false

    	t.timestamps
    end
    add_column :users, :latitude, :float
    add_column :users, :longitude, :float
    add_index :post_passes, :created_at
  end
end
