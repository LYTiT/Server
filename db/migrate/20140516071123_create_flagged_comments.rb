class CreateFlaggedComments < ActiveRecord::Migration
  def change
    create_table :flagged_comments do |t|
      t.integer :venue_comment_id
      t.integer :user_id
      t.text :message
      t.timestamps
    end
  end
end
