class ModifyVenueComments < ActiveRecord::Migration
  def change
  	remove_column :venue_comments, :num_views
  	add_column :venue_comments, :tweet, :json, default: {}, null: false
  	add_column :venue_comments, :event, :json, default: {}, null: false
  end
end
