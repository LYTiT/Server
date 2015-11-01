class AddUserToSupportMessages < ActiveRecord::Migration
  def change
  	add_column :support_messages, :user_id, :integer
  end
end
