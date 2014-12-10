json.set! :venue do
  json.set! :id, @venue.id
  json.set! :name, @venue.name
  json.set! :latitude, @venue.latitude
  json.set! :longitude, @venue.longitude
  json.set! :rating, @venue.rating
end

json.set! :group do
  json.set! :id, @group.id
  json.set! :name, @group.name
end
