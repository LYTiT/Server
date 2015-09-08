class AddPopularityScoreToTweets < ActiveRecord::Migration
  def change
  	add_column :tweets, :popularity_score, :float
  end
end
