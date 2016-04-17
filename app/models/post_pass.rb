class PostPass < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue_comment

	def pass_on

	end

	def terminate
	end

	def select_next_users
		"SELECT user_id FROM post_passes WHERE"
	end

end