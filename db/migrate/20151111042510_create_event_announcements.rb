class CreateEventAnnouncements < ActiveRecord::Migration
  def change
    create_table :event_announcements do |t|
    	t.references :event, index: true
    	t.text :comment
    	t.references :user, index: true

    	t.timestamps
    end
  end
end
