class CouponClaimer < ActiveRecord::Base
  belongs_to :coupon
  belongs_to :user
end