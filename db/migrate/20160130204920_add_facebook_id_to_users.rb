class AddFacebookIdToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :facebook_id, :integer, :limit => 8
  	add_column :users, :facebook_name, :string
  	add_column :activities, :user_facebook_id, :integer, :limit => 8
  	add_column :activities, :user_facebook_name, :string
  end
end
