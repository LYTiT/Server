class AddActiveToBountyClaimRejectionTrackers < ActiveRecord::Migration
  def change
  	add_column :bounty_claim_rejection_trackers, :active, :boolean, :default => true
  end
end
