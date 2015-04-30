class AddVenueCommentIdToBounties < ActiveRecord::Migration
  def change
  	add_column :bounties, :venue_comment_id, :integer
  end
end
