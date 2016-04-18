class AddColumnsToVenueCommentsAndUsers < ActiveRecord::Migration
  def change
  	add_column :users, :violations, :json, default: {}, null: false
  	add_column :venue_comments, :visible, :boolean, :default => true
  	add_column :venue_comments, :active, :boolean, :default => true
  end
end
