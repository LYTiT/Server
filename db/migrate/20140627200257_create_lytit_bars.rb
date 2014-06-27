class CreateLytitBars < ActiveRecord::Migration
  def change
    create_table :lytit_bars do |t|
      t.float :position
    end
  end
end
