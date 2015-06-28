class CreateInstagramAuthTokens < ActiveRecord::Migration
  def change
    create_table :instagram_auth_tokens do |t|
    	t.string :token
    	t.integer :num_used, :default => 0
    	t.boolean :is_valid
    	t.integer :instagram_user_id
    	t.string :instagram_username
    	t.references :user, index: true
    	t.timestamps
    end
  end
end
