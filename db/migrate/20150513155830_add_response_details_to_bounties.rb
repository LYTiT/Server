class AddResponseDetailsToBounties < ActiveRecord::Migration
  def change
  	add_column :bounties, :latest_response_1, :string
  	add_column :bounties, :latest_response_2, :string
  end
end
