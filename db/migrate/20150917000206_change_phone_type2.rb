class ChangePhoneType2 < ActiveRecord::Migration
  def change
  	change_column :users, :phone_number, :integer, :limit => 5
  end
end
