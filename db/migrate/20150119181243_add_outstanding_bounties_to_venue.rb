class AddOutstandingBountiesToVenue < ActiveRecord::Migration
  def change
  	add_column :venues, :outstanding_bounties, :integer, :default => 0
  end
end
