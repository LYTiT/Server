class CreateLiveUsers < ActiveRecord::Migration
  def change
    create_table :live_users do |t|
    	t.references :venue, index: true
    	t.references :user, index: true

    	t.timestamps
    end
  end
end
