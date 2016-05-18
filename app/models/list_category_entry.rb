class ListCategoryEntry < ActiveRecord::Base
  belongs_to :feed
  belongs_to :list_category

  def ListCategoryEntry.bulk_create(category_ids, feed_id)
  	category_ids.each{|category_id| ListCategoryEntry.create!(:feed_id => feed_id, :list_category_id => category_id)}
  end

  def ListCategoryEntry.bulk_remove(category_ids, feed_id)
  	category_ids.each{|category_id| ListCategoryEntry.where("feed_id = ? AND list_category_id = ?", feed_id, category_id).delete_all}
  end

  
end