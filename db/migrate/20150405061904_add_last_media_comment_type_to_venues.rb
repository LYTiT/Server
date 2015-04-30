class AddLastMediaCommentTypeToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :last_media_comment_type, :string
  end
end
