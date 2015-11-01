class AddValidityToBounty < ActiveRecord::Migration
  def change
  	add_column :bounties, :validity, :boolean, :default => true
  end
end
