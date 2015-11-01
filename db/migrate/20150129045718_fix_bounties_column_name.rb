class FixBountiesColumnName < ActiveRecord::Migration
  def change
  	rename_column :bounties, :time_expiration, :expiration
  end
end
