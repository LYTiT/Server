class CreateFlaggedGroups < ActiveRecord::Migration
  def change
    create_table :flagged_groups do |t|
      t.references :user, index: true
      t.references :group, index: true
      t.text :message
      
      t.timestamps
    end
  end
end
