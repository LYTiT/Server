class AddCategoryIndexToFeedRecommendations < ActiveRecord::Migration
  def change
  	add_index "feed_recommendations", ["category"]
  end
end
