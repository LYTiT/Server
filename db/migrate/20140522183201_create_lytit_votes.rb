class CreateLytitVotes < ActiveRecord::Migration
  def change
    create_table :lytit_votes do |t|
      t.integer :value
      t.references :venue, index: true
      t.references :user, index: true

      t.timestamps
    end
  end
end
