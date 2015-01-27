class CreateBounties < ActiveRecord::Migration
  def change
    create_table :bounties do |t|
		t.integer :lumen_reward
		t.string :expiration
		t.references :user, index: true
		t.references :venue, index: true
		
		t.timestamps
    end
  end
end
