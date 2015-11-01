class AddRejectedToBountyClaims < ActiveRecord::Migration
  def change
  	add_column :bounty_claims, :rejected, :boolean, :default => false
  end
end
