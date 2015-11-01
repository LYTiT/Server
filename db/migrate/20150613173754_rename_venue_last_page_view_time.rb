class RenameVenueLastPageViewTime < ActiveRecord::Migration
  def change
  	rename_column :venues, :last_page_view_time, :latest_page_view_time
  end
end
