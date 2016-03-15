class AddColumnsToVenueComments < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :geo_views, :json, default: {}, null: false
  end
end
