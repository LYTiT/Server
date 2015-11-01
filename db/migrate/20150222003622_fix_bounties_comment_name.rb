class FixBountiesCommentName < ActiveRecord::Migration
  def change
  	rename_column :bounties, :comment, :detail
  end
end
