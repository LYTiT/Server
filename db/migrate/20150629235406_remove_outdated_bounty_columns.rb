class RemoveOutdatedBountyColumns < ActiveRecord::Migration
  def change
  	remove_column :lumen_values, :bounty_id, :integer
  	remove_column :users, :bounty_lumens, :float
  	remove_column :users, :can_claim_bounty, :boolean
  	remove_column :venue_comments, :bounty_id, :integer
  	remove_column :venues, :outstanding_bounties, :integer
  	remove_column :venues, :latest_placed_bounty_time, :datetime
  end
end
