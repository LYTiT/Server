class AddLastInstPostToVenue < ActiveRecord::Migration
  def change
  	add_column :venues, :last_instagram_post, :string
  end
end
