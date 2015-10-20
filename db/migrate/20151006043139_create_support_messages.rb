class CreateSupportMessages < ActiveRecord::Migration
  def change
    create_table :support_messages do |t|
    	t.text :message
    	t.references :support_issue, index: true
    	t.timestamps
    end
  end
end
