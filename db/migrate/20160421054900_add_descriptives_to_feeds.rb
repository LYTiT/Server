class AddDescriptivesToFeeds < ActiveRecord::Migration
  def change
  	add_column :feeds, :venue_attributes, :json, default: {"descriptives" => {}, "venue_categories" => {}}, null: false
  	add_column :feeds, :venue_attributes_string, :string
  end
end
