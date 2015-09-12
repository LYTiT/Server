class AddMediaColumnsToVenueComments < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :image_url_2, :string
  	add_column :venue_comments, :image_url_3, :string
  	add_column :venue_comments, :video_url_1, :string
  	add_column :venue_comments, :video_url_2, :string
  	add_column :venue_comments, :video_url_3, :string
  end
end
