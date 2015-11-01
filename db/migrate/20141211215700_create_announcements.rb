class CreateAnnouncements < ActiveRecord::Migration
  def change
    create_table :announcements do |t|
      t.string :news
      t.boolean :send_to_all, :default => false

      t.timestamps
    end
  end
end
