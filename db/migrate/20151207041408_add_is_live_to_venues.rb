class AddIsLiveToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :is_live, :boolean, :index => true, :default => false
  end
end
