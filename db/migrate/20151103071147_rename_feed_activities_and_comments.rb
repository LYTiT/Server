class RenameFeedActivitiesAndComments < ActiveRecord::Migration
  def change
  	rename_table :feed_activities, :activities
  	rename_table :feed_activity_comments, :activity_comments
  end
end
