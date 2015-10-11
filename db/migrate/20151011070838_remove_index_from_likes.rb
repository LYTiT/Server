class RemoveIndexFromLikes < ActiveRecord::Migration
  def change
  	remove_index :likes, [:liked_id, :liker_id]
  end
end
