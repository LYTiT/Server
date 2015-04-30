class FixBountyClaimRejectionTrackerColumnName < ActiveRecord::Migration
  def change
  	rename_column :bounty_claim_rejection_trackers, :bounty_claim_id, :venue_comment_id
  end
end
