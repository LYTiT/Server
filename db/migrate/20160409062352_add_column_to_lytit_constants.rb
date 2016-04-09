class AddColumnToLytitConstants < ActiveRecord::Migration
  def change
  	add_column :lytit_constants, :big_value, :integer, :limit => 8
  end
end
