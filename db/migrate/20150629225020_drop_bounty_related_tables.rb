class DropBountyRelatedTables < ActiveRecord::Migration
  def change
  	drop_table :bounties
  	drop_table :bounty_claim_rejection_trackers
  	drop_table :bounty_pricing_constants
  	drop_table :bounty_subscribers
  	drop_table :coupons
  	drop_table :coupon_claimers
  	drop_table :lumen_game_winners
  end
end
