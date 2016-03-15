class CreateMomentRequests < ActiveRecord::Migration
  def change
    create_table :moment_requests do |t|
		t.references :venue, index: true
    	t.references :user, index: true
    end
  end
end
