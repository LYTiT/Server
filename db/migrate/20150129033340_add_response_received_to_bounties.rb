class AddResponseReceivedToBounties < ActiveRecord::Migration
  def change
  	add_column :bounties, :response_received, :boolean, :default => false
  end
end
