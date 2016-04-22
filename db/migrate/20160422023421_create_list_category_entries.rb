class CreateListCategoryEntries < ActiveRecord::Migration
  def change
    create_table :list_category_entries do |t|
    	t.references :feed, index: true
    	t.references :list_category, index: true

    	t.timestamps    	
    end
  end
end
