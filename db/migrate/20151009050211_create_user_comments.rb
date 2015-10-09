class CreateUserComments < ActiveRecord::Migration
  def change
    create_table :user_comments do |t|
		t.references :feed_activity, index: true
		t.references :user, index: true
    	t.text :comment
    	
    	t.timestamps
    end
  end
end
