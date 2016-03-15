class CreateReportedObjects < ActiveRecord::Migration
  def change
    create_table :reported_objects do |t|
    	t.string :type
    	t.integer :reporter_id
    	t.references :user
    	t.references :venue_comment
    	t.references :feed

    	t.timestamps
    end
  end
end
