class CreateFeeds < ActiveRecord::Migration
  def change
    create_table :feeds do |t|
    	t.string :name
    	t.references :user, index: true

    	t.timestamps
    end
    add_index :feeds, :name
  end
end
