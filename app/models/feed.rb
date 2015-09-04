class Feed < ActiveRecord::Base
	has_many :feed_venues, :dependent => :destroy
	has_many :venues, through: :feed_venues
	has_many :venue_comments, through: :venues
	has_many :feed_users, :dependent => :destroy
	has_many :feed_messages, :dependent => :destroy

	belongs_to :user

	def comments
		venue_ids = "SELECT venue_id FROM feeds WHERE id = #{self.id}"
		comments = VenueComment.where("venue_id IN (#{venue_ids}) AND (NOW() - created_at) <= INTERVAL '1 DAY'").order("id desc")
	end

	def is_venue_present?(v_id)
		FeedVenue.where("feed_id = ? AND venue_id = ?", self.id, v_id).any?
	end

	def new_content_present?
		latest_viewed_time_wrapper = latest_viewed_time || (Time.now + 1.minute)
		self.venue_comments.where("venue_comments.created_at > ?", latest_viewed_time_wrapper).count
	end

	def update_media
		self.venues.each do |v|
			v.instagram_pull_check
		end
	end

	def has_added?(new_user)
		FeedUser.where("user_id = ? AND feed_id = ?", new_user.id, id).any?
	end

	def calibrate_num_members
		self.update_columns(num_users: self.feed_users.count)
	end

	def new_content_for_user?(target_user)
		feeduser = FeedUser.where("user_id = ? AND feed_id = ?", target_user.id, self.id).first
		if self.latest_content_time == nil
			false
		elsif feeduser.last_visit == nil
			true
		else
			if self.latest_content_time > feeduser.last_visit
				true
			else
				false
			end
		end
	end

	def self.meta_search(query)
		direct_results = Feed.where("name LIKE (?) OR description LIKE (?)", "%"+query+"%", "%"+query+"%").to_a
		meta_results = Feed.joins(:feed_venues).joins(:venues => :meta_datas).where("meta LIKE (?)", query+"%").where("feeds.id NOT IN (?)", direct_results.map(&:id)).to_a.uniq{|x| x.id}.count
		merge = direct_results << meta_results
		results = merge.flatten.sort_by{|x| x.name}
	end

	def self.categories
		categories = []
	end

	def self.spotlyts

	end

end