class AddBountyToLumenValues < ActiveRecord::Migration
  def change
  	add_column :lumen_values, :bounty_id, :integer
  end
end
