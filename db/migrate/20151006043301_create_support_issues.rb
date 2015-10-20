class CreateSupportIssues < ActiveRecord::Migration
  def change
    create_table :support_issues do |t|
    	t.references :user, index: true
    	t.datetime :latest_message_time
    	t.datetime :latest_open_time
    	t.timestamps
    end
  end
end
