class CreateMenuSectionItems < ActiveRecord::Migration
  def change
    create_table :menu_section_items do |t|
      t.string :name
      t.float :price
      t.references :menu_section, index: true
      t.text :description

      t.timestamps
    end
  end
end
