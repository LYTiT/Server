class CreateFavoriteVenues < ActiveRecord::Migration
  def change
    create_table :favorite_venues do |t|    	
    	t.references :venue
    	t.references :user, index: true
    	t.float :interest_score, :default => 1.0
    	t.integer :num_new_moments
    	t.datetime :latest_venue_check_time
    	t.string :venue_name, index: true
    	t.json :venue_details, default: {}, null: false

    	t.timestamps    	
    end
  end
end
