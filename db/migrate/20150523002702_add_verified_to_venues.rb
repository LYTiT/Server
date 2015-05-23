class AddVerifiedToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :verified, :boolean, :default => true
  end
end
