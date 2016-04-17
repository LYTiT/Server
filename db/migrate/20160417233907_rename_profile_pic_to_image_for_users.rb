class RenameProfilePicToImageForUsers < ActiveRecord::Migration
  def change
  	rename_column :users, :profile_picture_url, :profile_image_url
  end
end
