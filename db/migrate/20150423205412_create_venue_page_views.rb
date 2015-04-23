class CreateVenuePageViews < ActiveRecord::Migration
  def change
    create_table :venue_page_views do |t|
    	t.references :user, index: true
		t.references :venue, index: true
		t.string :venue_l_sphere, index: true
		
		t.timestamps
    end
    add_index :venue_page_views, :venue_l_sphere
  end
end
