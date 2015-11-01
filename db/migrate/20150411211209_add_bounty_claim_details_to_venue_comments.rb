class AddBountyClaimDetailsToVenueComments < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :is_response, :boolean
  	add_column :venue_comments, :is_response_accepted, :boolean
  	add_column :venue_comments, :rejection_reason, :string
  end
end
