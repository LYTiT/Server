class AddCodeToFeeds < ActiveRecord::Migration
  def change
  	add_column :feeds, :code, :string
  end
end
