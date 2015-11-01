class AddCoverMediaUrlToGroups < ActiveRecord::Migration
  def change
  	add_column :groups, :cover_image_url_1, :string
  end
end
