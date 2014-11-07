class AddCommentIdToLumenValues < ActiveRecord::Migration
  def change
  	add_column :lumen_values, :venue_comment_id, :integer
  end
end
