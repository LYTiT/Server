class RenameUserComments < ActiveRecord::Migration
  def change
    rename_table :user_comments, :feed_activity_comments
  end
end
