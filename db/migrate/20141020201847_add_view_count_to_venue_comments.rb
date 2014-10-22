class AddViewCountToVenueComments < ActiveRecord::Migration
  def change
    add_column :venue_comments, :views, :integer, default: 0
  end
end
