json.set! :venue do
  json.set! :id, @venue.id
  json.set! :name, @venue.name
  json.set! :latitude, @venue.latitude
  json.set! :longitude, @venue.longitude
  json.set! :rating, @venue.rating
  json.set! :media_url, @venue.last_media_comment_url
  json.set! :media_type, @venue.last_media_comment_type
end

json.set! :group do
  json.set! :id, @group.id
  json.set! :name, @group.name
end
