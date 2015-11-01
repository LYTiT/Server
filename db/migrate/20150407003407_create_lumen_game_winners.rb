class CreateLumenGameWinners < ActiveRecord::Migration
  def change
    create_table :lumen_game_winners do |t|
    	t.references :user, index: true
    	t.integer :winning_validation_code
    	t.string :paypal_info
    	t.boolean :payment_made
    	t.boolean :validated

    	t.timestamps
    end
  end
end
