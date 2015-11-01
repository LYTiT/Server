class AddVendorIdToUser < ActiveRecord::Migration
  def change
  	add_column :users, :vendor_id, :string
  end
end
