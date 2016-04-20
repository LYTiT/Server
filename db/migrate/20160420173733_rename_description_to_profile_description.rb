class RenameDescriptionToProfileDescription < ActiveRecord::Migration
  def change
  	rename_column :users, :description, :profile_description
  end
end
