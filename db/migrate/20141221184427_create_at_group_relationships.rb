class CreateAtGroupRelationships < ActiveRecord::Migration
  def change
    create_table :at_group_relationships do |t|
      t.integer :venue_comment_id
      t.integer :group_id

      t.timestamps
    end
    add_index :at_group_relationships, :venue_comment_id
    add_index :at_group_relationships, :group_id
    add_index :at_group_relationships, [:venue_comment_id, :group_id], unique: true
  end
end