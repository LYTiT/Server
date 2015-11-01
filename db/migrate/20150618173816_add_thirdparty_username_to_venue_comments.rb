class AddThirdpartyUsernameToVenueComments < ActiveRecord::Migration
  def change
  	add_column :venue_comments, :thirdparty_username, :string
  end
end
