class Bounty < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue

	def is_valid?
		if self.expiration - self.created_at < 0
			self.validity = false
			save
			return false
		else
			return true
		end
	end

end