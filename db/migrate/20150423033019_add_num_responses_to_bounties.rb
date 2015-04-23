class AddNumResponsesToBounties < ActiveRecord::Migration
  def change
  	add_column :bounties, :num_responses, :integer, :default => 0
  end
end
