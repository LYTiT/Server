class AddInstagramIdToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :venue_comment_instagram_id, :string
  	
  end
end
