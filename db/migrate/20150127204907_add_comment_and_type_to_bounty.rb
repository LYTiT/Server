class AddCommentAndTypeToBounty < ActiveRecord::Migration
  def change
  	add_column :bounties, :type, :string
  	add_column :bounties, :comment, :string
  end
end
