class AddUniqueIndexToMetaDataVenuePair < ActiveRecord::Migration
  def change
  	add_index "meta_data", ["meta", "venue_comment_id"], :unique => true
  end
end
