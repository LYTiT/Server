class AddDescriptionAndPreviewPicToUser < ActiveRecord::Migration
  def change
  	add_column :users, :description, :text
  	add_column :users, :profile_picture_url, :text
  end
end
