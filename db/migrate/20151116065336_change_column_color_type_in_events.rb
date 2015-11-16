class ChangeColumnColorTypeInEvents < ActiveRecord::Migration
  def change
  	change_column :events, :color, :string
  end
end
