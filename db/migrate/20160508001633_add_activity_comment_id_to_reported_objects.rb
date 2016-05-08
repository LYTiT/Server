class AddActivityCommentIdToReportedObjects < ActiveRecord::Migration
  def change
  	add_column :reported_objects, :activity_comment_id, :integer
  end
end
