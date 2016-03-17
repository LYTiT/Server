class ModifyEvents < ActiveRecord::Migration
  def change
  	remove_column :events, :color
  	add_column :events, :category, :string
  	add_column :events, :source, :string
  	add_column :events, :source_url, :text
  end
end
