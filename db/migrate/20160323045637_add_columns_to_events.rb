class AddColumnsToEvents < ActiveRecord::Migration
  def change
  	add_column :events, :eventbrite_id, :integer, :limit => 8, :index => true
  	add_column :events, :cover_image_url, :text
  end
end
