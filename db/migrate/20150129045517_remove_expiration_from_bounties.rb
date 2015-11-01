class RemoveExpirationFromBounties < ActiveRecord::Migration
  def change
  	remove_column :bounties, :expiration, :string
  end
end
