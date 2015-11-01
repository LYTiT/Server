class CreateFlaggedEvents < ActiveRecord::Migration
  def change
    create_table :flagged_events do |t|
      t.integer :event_id
      t.integer :user_id
      t.text :message
      t.timestamps
    end
  end
end
