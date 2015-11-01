class AddBountyClaimIdToVenueComments < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :bounty_claim_id, :integer
  end
end
