class ChangePhoneType < ActiveRecord::Migration
  def change
  	change_column :users, :phone_number, :int4, :limit => 4
  end
end
