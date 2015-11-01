class RemoveLastMediaCommentIdFromVenues < ActiveRecord::Migration
  def change
  	remove_column :venues, :last_media_comment_id
  end
end
