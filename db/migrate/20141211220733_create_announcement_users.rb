class CreateAnnouncementUsers < ActiveRecord::Migration
  	def change
	    create_table :announcement_users do |t|
	    	t.integer :user_id
	    	t.integer :announcement_id
	    	t.timestamps
	    end
	    add_index :announcement_users, :user_id
	    add_index :announcement_users, :announcement_id
	end
end
