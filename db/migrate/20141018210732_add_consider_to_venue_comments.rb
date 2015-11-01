class AddConsiderToVenueComments < ActiveRecord::Migration
  def change
    add_column :venue_comments, :consider, :integer
  end
end
