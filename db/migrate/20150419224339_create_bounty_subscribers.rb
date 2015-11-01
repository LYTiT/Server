class CreateBountySubscribers < ActiveRecord::Migration
  def change
    create_table :bounty_subscribers do |t|
    	t.references :bounty, index: true
		t.references :user, index: true
		
		t.timestamps
    end
  end
end
