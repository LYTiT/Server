class CreateBountyClaims < ActiveRecord::Migration
  def change
    create_table :bounty_claims do |t|
		t.references :user, index: true
		t.references :bounty, index: true
		t.references :venue_comment
		
		t.timestamps
    end
  end
end
