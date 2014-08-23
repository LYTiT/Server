json.array! @notifications do |notification|
  json.payload notification.payload
  json.details notification.response
  json.timestamp notification.created_at  
end
