class ChangeCountryCodeType < ActiveRecord::Migration
  def change
  	change_column :users, :country_code, :string
  end
end
