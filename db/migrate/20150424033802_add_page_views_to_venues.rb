class AddPageViewsToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :page_views, :integer, :default => 0
  end
end
