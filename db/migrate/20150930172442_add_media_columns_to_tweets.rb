class AddMediaColumnsToTweets < ActiveRecord::Migration
  def change
  	add_column(:tweets, :image_url_1, :string)
  	add_column(:tweets, :image_url_2, :string)
  	add_column(:tweets, :image_url_3, :string)
  end
end
