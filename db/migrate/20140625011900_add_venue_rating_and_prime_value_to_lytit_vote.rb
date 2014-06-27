class AddVenueRatingAndPrimeValueToLytitVote < ActiveRecord::Migration
  def change
    add_column :lytit_votes, :venue_rating, :float
    add_column :lytit_votes, :prime, :float
  end
end
