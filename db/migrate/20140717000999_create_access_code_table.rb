#This creates a table called "access_codes",
#table entries have two main fields, accesscode, kvalue, and created/modified timestamp fields
<<<<<<< HEAD:db/migrate/20140717989898_create_access_code_table.rb
#
=======

>>>>>>> c425e592d685a90e42a90230b5912a7632c07417:db/migrate/20140717000999_create_access_code_table.rb
class CreateAccessCodeTable < ActiveRecord::Migration
  def change
    create_table :access_codes do |t|
      t.string :accesscode
      t.integer :kvalue
      t.timestamps
    end
  end
end
