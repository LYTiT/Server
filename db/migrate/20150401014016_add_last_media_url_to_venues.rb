class AddLastMediaUrlToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :last_media_comment_url, :string
  end
end
