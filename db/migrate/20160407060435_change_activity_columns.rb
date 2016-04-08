class ChangeActivityColumns < ActiveRecord::Migration
  def change
  	rename_column :activities, :feed_venue, :feed_venue_details
  end
end
