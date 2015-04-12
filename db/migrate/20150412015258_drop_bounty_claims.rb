class DropBountyClaims < ActiveRecord::Migration
  def change
  	drop_table :bounty_claims
  end
end
