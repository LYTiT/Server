class AddGcmTokenToUsersTable < ActiveRecord::Migration
  def change
    add_column :users, :gcm_token, :string
  end
end
