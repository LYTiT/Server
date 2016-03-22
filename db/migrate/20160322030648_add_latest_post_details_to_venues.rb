class AddLatestPostDetailsToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :latest_post_details, :json, default: {}, null: false
  end
end
