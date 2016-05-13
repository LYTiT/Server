class FeedColumnTweaks < ActiveRecord::Migration
  def change
  	change_column :feeds, :in_spotlyt, :boolean, default: false
  end
end
