class ChangeRatingToFloat < ActiveRecord::Migration
  def change
    change_column :venues, :rating, :float
  end
end
