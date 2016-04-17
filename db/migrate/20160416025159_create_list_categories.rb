class CreateListCategories < ActiveRecord::Migration
  def change
    create_table :list_categories do |t|
    	t.string :name
    	t.json :tags, default: {}, null: false
    	t.integer :num_lists, default: 0
    	t.text :thumbnail_image_url

		t.timestamps    	
    end
    add_column :feeds, :list_category_id, :integer
  end
end
