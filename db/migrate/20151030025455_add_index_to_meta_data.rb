class AddIndexToMetaData < ActiveRecord::Migration
  def change
  	add_index "meta_data", ["created_at"]
  end
end
