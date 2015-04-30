class AddCanClaimBountyToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :can_claim_bounty, :boolean, :default => true
  end
end
