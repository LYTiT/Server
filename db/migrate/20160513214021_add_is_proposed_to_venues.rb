class AddIsProposedToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :is_proposed, :boolean, default: false
  end
end
