class AddHandleToTweets < ActiveRecord::Migration
  def change
  	add_column :tweets, :handle, :string
  end
end
