class AddDetailsToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :latest_posted_comment_time, :datetime
  	add_column :venues, :last_media_comment_id, :integer
  	add_column :venues, :is_address, :boolean, :default => false
  	add_column :venues, :has_been_voted_at, :boolean, :default => false
  end
end
