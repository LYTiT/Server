class AddPushTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :push_token, :text
  end
end
