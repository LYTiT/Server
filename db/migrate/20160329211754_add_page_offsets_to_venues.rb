class AddPageOffsetsToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :page_offset, :integer, :default => 0
  end
end
