class AddTimeWrapperToLytitVotes < ActiveRecord::Migration
  def change
  	add_column :lytit_votes, :time_wrapper, :datetime
  end
end
