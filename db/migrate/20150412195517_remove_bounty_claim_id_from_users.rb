class RemoveBountyClaimIdFromUsers < ActiveRecord::Migration
  def change
  	remove_column :venue_comments, :bounty_claim_id
  end
end
