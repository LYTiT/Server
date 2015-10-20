class CreateFeedInvitations < ActiveRecord::Migration
  def change
    create_table :feed_invitations do |t|
    	t.integer :inviter_id
    	t.integer :invitee_id
    	t.references :feed

    	t.timestamps    	
    end
    add_index :feed_invitations, :inviter_id
    add_index :feed_invitations, :invitee_id
  end
end
