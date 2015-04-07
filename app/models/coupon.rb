class Coupon < ActiveRecord::Base
	def Coupon.check_code(code, user)
		retrieved_coupon = Coupon.where("code = ?", code).first
		if retrieved_coupon != nil
			claimers_count = CouponClaimer.where("coupon_id = ?", retrieved_coupon.id).count
			if claimers_count >= retrieved_coupon.supply
				response = "Code expired. Please enter another code."
			else
				CouponClaimer.create!(coupon_id: retrieved_coupon.id, user_id: user.id)
				user.update_columns(lumens: retrieved_coupon.lumen_gift)
				response = "Nice! +#{retrieved_coupon.lumen_gift} Lumens."
				LumenValue.create!(value: retrieved_coupon.lumen_gift, user_id: user.id)
			end
		else
			response = "Code not valid."
		end

		return response
	end
end