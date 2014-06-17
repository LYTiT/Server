class CreateCommentViews < ActiveRecord::Migration
  def change
    create_table :comment_views do |t|
      t.references :venue_comment, index: true
      t.references :user, index: true

      t.timestamps
    end
    add_index :comment_views, [:venue_comment_id, :user_id], unique: true
  end
end
