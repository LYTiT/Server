class AddNewColumnsToVenueComments < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :content_origin, :string
  	add_column :venue_comments, :time_wrapper, :datetime
  end
end
