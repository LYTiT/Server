class AddDecrementVenueBountyCountToBounties < ActiveRecord::Migration
  def change
  	add_column :bounties, :decrement_venue_bounty_count, :boolean, :default => true
  end
end
