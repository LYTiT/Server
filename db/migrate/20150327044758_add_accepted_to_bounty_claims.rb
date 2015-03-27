class AddAcceptedToBountyClaims < ActiveRecord::Migration
  def change
  	add_column :bounty_claims, :accepted, :boolean
  end
end
