class AddCleanMetaToMetaDatas < ActiveRecord::Migration
  def change
  	add_column :meta_data, :clean_meta, :string
  end
end
