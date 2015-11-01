class AddRejectionReasonToBountyClaims < ActiveRecord::Migration
  def change
  	add_column :bounty_claims, :rejection_reason, :string
  end
end
