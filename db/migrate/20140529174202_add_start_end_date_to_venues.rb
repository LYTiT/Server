class AddStartEndDateToVenues < ActiveRecord::Migration
  def change
    add_column :venues, :start_date, :datetime
    add_column :venues, :end_date, :datetime
  end
end
