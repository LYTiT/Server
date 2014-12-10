class CreateGroupInvitations < ActiveRecord::Migration
  def change
    create_table :group_invitations do |t|
      t.integer :igroup_id
      t.integer :invited_id            
      t.integer :host_id

      t.timestamps
    end
    add_index :group_invitations, :igroup_id
    add_index :group_invitations, :invited_id     
    add_index :group_invitations, :host_id
    add_index :group_invitations, [:group_id, :invited_id], unique: true
  end
end
