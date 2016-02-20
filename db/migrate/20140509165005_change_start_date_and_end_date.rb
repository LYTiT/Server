class ChangeStartDateAndEndDate < ActiveRecord::Migration
  def up
    remove_column :old_events, :start_time
    remove_column :old_events, :end_time

    change_column :old_events, :start_date, :datetime
    change_column :old_events, :end_date, :datetime
  end

  def down
    add_column :old_events, :start_time, :string
    add_column :old_events, :end_time, :string

    change_column :old_events, :start_date, :date
    change_column :old_events, :end_date, :date
  end

end
