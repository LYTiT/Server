class CreateMetaData < ActiveRecord::Migration
  def change
    create_table :meta_data do |t|
    	t.string :meta
    	t.references :venue
    	t.references :venue_comment

    	t.timestamps
    end
    add_index :meta_data, :meta
  end
end
