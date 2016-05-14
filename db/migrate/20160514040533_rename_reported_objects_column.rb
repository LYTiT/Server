class RenameReportedObjectsColumn < ActiveRecord::Migration
  def change
  	rename_column :reported_objects, :type, :report_type
  end
end
