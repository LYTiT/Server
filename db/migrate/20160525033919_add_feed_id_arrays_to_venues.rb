class AddFeedIdArraysToVenues < ActiveRecord::Migration
  def change
  	enable_extension "btree_gin"
  	enable_extension "btree_gist"
  	add_column :venues, :linked_lists, :json, default: {}
  	add_column :venues, :linked_list_ids, :integer, array: true, default: []
  	add_index :venues, :linked_list_ids, using: :gin
  end
end
