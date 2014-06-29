class CreateMenuSections < ActiveRecord::Migration
  def change
    create_table :menu_sections do |t|
      t.string :name
      t.references :venue, index: true

      t.timestamps
    end
  end
end
