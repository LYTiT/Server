class ChangeDefaultValueOfUserVersion < ActiveRecord::Migration
  def up
  	change_column :users, :version, :string, :default => "1.0.0"
  end

  def down
  	change_column :users, :version, :string, :default => "3.0.0"
  end
end
