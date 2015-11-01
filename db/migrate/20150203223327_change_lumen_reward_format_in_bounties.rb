class ChangeLumenRewardFormatInBounties < ActiveRecord::Migration
  def up
    change_column :bounties, :lumen_reward, :float
  end

  def down
    change_column :bounties, :lumen_reward, :integer
  end
end
