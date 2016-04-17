class PostPass < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue_comment

	def pass_on

	end

	def terminate
	end

	def select_next_users
		previous_post_pass_user_ids = "SELECT user_id FROM post_passes WHERE venue_comment_id = #{self.venue_comment_id}"
		self.user.nearest_neighbors.where("id NOT IN (#{previous_post_pass_user_ids})")
	end

end