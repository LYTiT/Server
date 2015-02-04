class CreateBountyClaimRejectionTrackers < ActiveRecord::Migration
  def change
    create_table :bounty_claim_rejection_trackers do |t|
    	t.references :user, index: true
		t.references :bounty_claim, index: true
		
		t.timestamps
    end
  end
end
