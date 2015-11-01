class AddMoreLastestResponsesToBounties < ActiveRecord::Migration
  def change
  	add_column :bounties, :latest_response_3, :string
  	add_column :bounties, :latest_response_4, :string
   	add_column :bounties, :latest_response_5, :string
  	add_column :bounties, :latest_response_6, :string
  	add_column :bounties, :latest_response_7, :string
  	add_column :bounties, :latest_response_8, :string
  	add_column :bounties, :latest_response_9, :string
  	add_column :bounties, :latest_response_10, :string  	  	 
  end
end
