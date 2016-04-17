class PostPass < ActiveRecord::Base
	belongs_to :user
	belongs_to :venue_comment

	def pass_on
	end

	def terminate
	end

	def find_next_user(lat, long, radius)
		search_box = 
		previous_post_pass_user_ids = "SELECT user_id FROM post_passes WHERE venue_comment = #{self.venue_comment_id}"
		User.in_bounds(search_box).where("active IS TRUE AND id NOT IN (#{previous_post_pass_user_ids})").limit(10)
		radius_incrementer = 0.5 #kms
		self.increment!(:spread_radius, radius_incrementer)
	end

end