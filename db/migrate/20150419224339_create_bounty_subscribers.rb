class CreateBountySubscribers < ActiveRecord::Migration
  def change
    create_table :request_subscribers do |t|
    	t.references :bounty, index: true
		t.references :user, index: true
		
		t.timestamps
    end
  end
end
