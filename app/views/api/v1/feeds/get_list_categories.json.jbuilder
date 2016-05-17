json.array! @categories do |category|
	json.id category.id
	json.name category.name
	json.image_url_1 category.thumbnail_image_url
end