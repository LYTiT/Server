class AddMenuLinkToVenues < ActiveRecord::Migration
  def change
    add_column :venues, :menu_link, :string
  end
end
