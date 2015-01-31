class AddLastViewedClaimTimeToBounties < ActiveRecord::Migration
  def change
  	add_column :bounties, :last_viewed_claim_time, :datetime
  end
end
