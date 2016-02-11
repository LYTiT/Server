class AddInstagramIdToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :venue_comment_instagram_id, :string
  	add_column :venues, :venue_comment_instagram_user_id, :integer, :limit => 8
  end
end
