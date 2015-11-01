class CreateGroupsUsers < ActiveRecord::Migration
  def change
    create_table :groups_users do |t|
      t.integer :user_id
      t.integer :group_id
      t.boolean :is_admin, default: false
      t.timestamps
    end
  end
end
