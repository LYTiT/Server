json.array! @notifications do |notification|
  json.id notification.id
  json.read notification.try(:read)
  json.payload notification.try(:payload)
  json.details notification.try(:response)
  json.timestamp notification.try(:created_at)
  json.responded_to notification.try(:responded_to)
end
