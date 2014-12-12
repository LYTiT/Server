class AddActiveToGroupInvitations < ActiveRecord::Migration
  def change
    add_column :group_invitations, :active, :boolean, :default => true
  end
end
