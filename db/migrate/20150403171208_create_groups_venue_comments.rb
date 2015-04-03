class CreateGroupsVenueComments < ActiveRecord::Migration
  def change
    create_table :groups_venue_comments do |t|
    	t.references :venue_comment, index: true
    	t.references :group, index: true
    	t.boolean :is_hashtag
		
		t.timestamps
    end
  end
end
