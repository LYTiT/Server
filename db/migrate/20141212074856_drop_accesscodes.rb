class DropAccesscodes < ActiveRecord::Migration
  def up
  	#drop_table :accesscodes
  end

  def down
    create_table :accesscodes do |t|
      t.string :code
      t.integer :kvalue

      t.timestamps
    end
  end

end
