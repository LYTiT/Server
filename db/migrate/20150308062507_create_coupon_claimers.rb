class CreateCouponClaimers < ActiveRecord::Migration
  def change
    create_table :coupon_claimers do |t|
    	t.references :coupon, index: true
		t.references :user
		
		t.timestamps
    end
  end
end
