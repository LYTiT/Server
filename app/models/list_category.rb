class ListCategory < ActiveRecord::Base
	has_many :list_category_entries

	def ListCategory.populate
		rec_categories = FeedRecommendation.where("category IS NOT NULL").pluck(:category)
		for category in rec_categories
			lc = ListCategory.create!(:name => category)
			category_feeds = FeedRecommendation.where("category = ?", category)
			category_feeds.each{|feed| ListCategoryEntry.create!(:feed_id => feed.id, :list_category_id => lc.id)}
		end
	end

end