class AddOrderToMenuItems < ActiveRecord::Migration
  def change
    add_column :menu_section_items, :position, :integer
    add_column :menu_sections, :position, :integer
  end
end
