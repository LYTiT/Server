class CreateAccesscodes < ActiveRecord::Migration
  def change
    create_table :accesscodes do |t|
      t.string :code
      t.integer :kvalue

      t.timestamps
    end
  end
end
