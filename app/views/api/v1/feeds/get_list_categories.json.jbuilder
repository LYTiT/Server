json.array! @categories do |category|
  json.name category.name
  json.image_url_1 category.thumbnail_image_url
end