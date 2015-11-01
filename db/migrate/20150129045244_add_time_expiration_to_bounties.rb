class AddTimeExpirationToBounties < ActiveRecord::Migration
  def change
  	add_column :bounties, :time_expiration, :datetime
  end
end
