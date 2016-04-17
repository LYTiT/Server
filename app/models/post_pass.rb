class PostPass < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue_comment

	def pass_on
		self.update_columns(passed_on: true)
		next_users = self.select_next_users
		for next_user in next_users

		end
	end

	def terminate
		self.update_columns(passed_on: false)
	end

	def report
	end

	def select_next_users
		previous_post_pass_user_ids = "SELECT user_id FROM post_passes WHERE venue_comment_id = #{self.venue_comment_id}"
		self.user.nearest_neighbors.where("id NOT IN (#{previous_post_pass_user_ids})")
	end

end