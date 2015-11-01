class AddCommentAndMediaTypeToBounty < ActiveRecord::Migration
  def change
  	add_column :bounties, :media_type, :string
  	add_column :bounties, :comment, :string
  end
end
