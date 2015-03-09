class CreateCoupons < ActiveRecord::Migration
  def change
    create_table :coupons do |t|
    	t.string :code
    	t.float :lumen_gift
    	t.integer :supply
		
		t.timestamps
    end
  end
end
