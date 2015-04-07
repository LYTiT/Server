class FixLumenGameWinnerColumnName < ActiveRecord::Migration
  def change
  	rename_column :lumen_game_winners, :validated, :email_sent
  end
end
