class AddAdjustedViewDiscountToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :adjusted_view_discount, :float
  end
end
