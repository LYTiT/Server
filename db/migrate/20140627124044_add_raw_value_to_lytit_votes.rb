class AddRawValueToLytitVotes < ActiveRecord::Migration
  def change
    add_column :lytit_votes, :raw_value, :float
  end
end
