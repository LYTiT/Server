class CreateLumenValues < ActiveRecord::Migration
  def change
    create_table :lumen_values do |t|
      t.float :value
      t.references :user, index: true

      t.timestamps
    end
  end
end
