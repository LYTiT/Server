class RenameVenueCommentColumn < ActiveRecord::Migration
  def change
  	rename_column :venue_comments, :media_url, :image_url_1
  end
end
