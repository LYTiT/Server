class AddPostDimensionsToVenueComments < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :media_dimensions, :string
  end
end
