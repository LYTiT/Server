class FixLumenColumnComment < ActiveRecord::Migration
  def change
  	rename_column :lumen_values, :comment_id, :venue_comment_id
  end
end
