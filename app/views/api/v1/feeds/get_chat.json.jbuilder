json.array! @messages do |message|
  json.id message.id
  json.user_id message.user_id
  json.user_name message.user.try(:name)
  json.user_phone message.user.try(:phone)
  json.chat_message message.message
  json.timestamp message.created_at
end