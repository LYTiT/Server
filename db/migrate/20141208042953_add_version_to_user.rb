class AddVersionToUser < ActiveRecord::Migration
  def change
    add_column :users, :version, :string, :default => "3.0.0"
  end
end
