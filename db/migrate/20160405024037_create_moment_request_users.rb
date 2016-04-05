class CreateMomentRequestUsers < ActiveRecord::Migration
  def change
    create_table :moment_request_users do |t|
    	t.references :user
    	t.references :moment_request

    	t.timestamps    	
    end
  end
end
