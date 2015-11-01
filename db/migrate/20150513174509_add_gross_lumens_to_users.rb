class AddGrossLumensToUsers < ActiveRecord::Migration
  def change
  	add_column :users, :monthly_gross_lumens, :float, :default => 0.0
  end
end
