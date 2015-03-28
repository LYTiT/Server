class AddCoverMediaUrlToGroups < ActiveRecord::Migration
  def change
  	add_column :groups, :cover_media_url, :string
  end
end
