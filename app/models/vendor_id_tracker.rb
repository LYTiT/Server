class VendorIdTracker < ActiveRecord::Base

	def VendorIdTracker.implicit_creation(u_id)
		if VendorIdTracker.where("LOWER(used_vendor_id) = ?", @user.vendor_id.downcase).first.nil? == true
  			VendorIdTracker.create!(:used_vendor_id => u_id)
  		end
	end


end