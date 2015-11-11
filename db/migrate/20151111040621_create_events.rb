class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
    	t.string :name
    	t.text :description
    	t.text :color
    	t.datetime :start_time
    	t.datetime :end_time    	
    	t.references :venue, index: true
    	t.string :low_image_url
    	t.string :medium_image_url
    	t.string :regular_image_url

    	t.timestamps
    end
  end
end
