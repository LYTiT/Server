class RemoveUniqueUserCommentViewIndex < ActiveRecord::Migration
  def change
  	remove_index(:comment_views, :name => 'index_comment_views_on_venue_comment_id_and_user_id')
  end
end
