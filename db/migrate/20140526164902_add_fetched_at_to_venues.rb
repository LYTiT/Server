class AddFetchedAtToVenues < ActiveRecord::Migration
  def change
    add_column :venues, :fetched_at, :datetime
  end
end
