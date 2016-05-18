json.array! @categories do |category|
	json.id category.id
	json.name category.name
	json.image_url_1 category.thumbnail_image_url
	json.assigned ListCategoryEntry.find_by_feed_id_and_list_category_id(@feed.id, category.id).present?
end