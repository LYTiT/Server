class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name
      t.string :description
      t.string :can_link_event #can link event
      t.boolean :is_public
      t.string :password

      t.timestamps
    end
  end
end
