json.array! @messages do |message|
  json.id message.id
  json.user_id message.user_id
  json.user_name message.user.name
  json.user_phone message.user.phone
  json.chat_message message.message
end