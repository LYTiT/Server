class AddTopTagsToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :tag_1, :string
  	add_column :venues, :tag_2, :string
  	add_column :venues, :tag_3, :string
  	add_column :venues, :tag_4, :string
  	add_column :venues, :tag_5, :string
  end
end
