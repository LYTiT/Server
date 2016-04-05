class TweakVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :event, :json, default: {}, null: false
  	rename_column :venues, :latest_post_details, :latest_post
  end
end
