class ChangeStartDateAndEndDate < ActiveRecord::Migration
  def up
    remove_column :events, :start_time
    remove_column :events, :end_time

    change_column :events, :start_date, :datetime
    change_column :events, :end_date, :datetime
  end

  def down
    add_column :events, :start_time, :string
    add_column :events, :end_time, :string

    change_column :events, :start_date, :date
    change_column :events, :end_date, :date
  end

end
