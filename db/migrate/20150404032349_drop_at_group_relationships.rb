class DropAtGroupRelationships < ActiveRecord::Migration
  def change
  	drop_table :at_group_relationships
  end
end
