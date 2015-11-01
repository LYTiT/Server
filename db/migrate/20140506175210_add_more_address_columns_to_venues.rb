class AddMoreAddressColumnsToVenues < ActiveRecord::Migration
  def change
    add_column :venues, :region, :string
    add_column :venues, :country, :string
    add_column :venues, :postal_code, :string
    add_column :venues, :formatted_address, :text
    add_column :venues, :google_place_reference, :text
  end
end
