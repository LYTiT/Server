class CreateLikes < ActiveRecord::Migration
  def change
    create_table :likes do |t|
    	t.integer :liked_id
    	t.integer :liker_id
    	t.string :type
    	t.references :feed_message
    	t.references :feed_venue    	

    	t.timestamps    	
    end
    add_index :likes, :liked_id
    add_index :likes, :liker_id
    add_index :likes, [:liked_id, :liker_id], unique: true
  end
end
