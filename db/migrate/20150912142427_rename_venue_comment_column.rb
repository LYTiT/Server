class RenameVenueCommentColumn < ActiveRecord::Migration
  def change
  	rename_column :venue_comments, :image_url_1, :image_url_1
  end
end
