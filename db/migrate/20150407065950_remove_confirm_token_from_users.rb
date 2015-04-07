class RemoveConfirmTokenFromUsers < ActiveRecord::Migration
  def change
  	remove_column :users, :confirm_token
  end
end
