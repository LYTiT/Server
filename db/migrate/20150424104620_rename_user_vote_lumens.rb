class RenameUserVoteLumens < ActiveRecord::Migration
  def change
  	rename_column :users, :vote_lumens, :bonus_lumens
  end
end
