class CreateBountyPricingConstants < ActiveRecord::Migration
  def change
    create_table :bounty_pricing_constants do |t|
    	t.string :constant_name
    	t.float :constant_value

    	t.timestamps
    end
  end
end
