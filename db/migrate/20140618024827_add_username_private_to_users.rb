class AddUsernamePrivateToUsers < ActiveRecord::Migration
  def change
    add_column :users, :username_private, :boolean, default: false
  end
end
