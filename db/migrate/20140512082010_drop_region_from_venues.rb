class DropRegionFromVenues < ActiveRecord::Migration
  def up
    remove_column :venues, :region
  end

  def down
    add_column :venues, :region, :string
  end

end
