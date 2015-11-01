class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name
      t.string :description
      t.boolean :can_link_events
      t.boolean :can_link_venues
      t.boolean :is_public
      t.string :password

      t.timestamps
    end
  end
end
