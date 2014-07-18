#This creates a table called "AccessCodes",
#table entries have two main fields, accesscode, kvalue, and created/modified timestamp fields
class CreateAccessCodeTable < ActiveRecord::Migration
  def change
    create_table :AccessCodes do |t|
      t.string :accesscode
      t.int :kvalue
      t.timestamps
    end
  end
end
