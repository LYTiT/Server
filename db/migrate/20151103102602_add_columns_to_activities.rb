class AddColumnsToActivities < ActiveRecord::Migration
  def change
  	add_column :activities, :venue_comment_id, :integer
  	add_column :activities, :message, :text
  end
end
