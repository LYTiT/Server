class AddPreviewImageToFeedRecommendations < ActiveRecord::Migration
  def change
  	add_column :feed_recommendations, :image_url, :string
  end
end
