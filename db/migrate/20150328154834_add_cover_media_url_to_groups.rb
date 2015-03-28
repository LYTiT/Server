class AddCoverMediaUrlToGroups < ActiveRecord::Migration
  def change
  	add_column :groups, :media_url, :string
  end
end
