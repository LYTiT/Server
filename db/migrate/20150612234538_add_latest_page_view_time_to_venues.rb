class AddLatestPageViewTimeToVenues < ActiveRecord::Migration
  def change
  	add_column :venues, :last_page_view_time, :datetime
  end
end
