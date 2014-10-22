class AddAdjViewCountToVenueComments < ActiveRecord::Migration
  def change
    add_column :venue_comments, :adj_views, :float, default: 0.0
  end
end
