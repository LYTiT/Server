class ChangeVenuePageViewType < ActiveRecord::Migration
  def change
  	change_column :venues, :page_views, :float
  end
end
