#This creates a table called "access_codes",
#table entries have two main fields, accesscode, kvalue, and created/modified timestamp fields
#
class CreateAccessCodeTable < ActiveRecord::Migration
  def change
    create_table :access_codes do |t|
      t.string :accesscode
      t.integer :kvalue
      t.timestamps
    end
  end
end
