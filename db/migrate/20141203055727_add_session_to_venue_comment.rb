class AddSessionToVenueComment < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :session, :integer
  end
end
