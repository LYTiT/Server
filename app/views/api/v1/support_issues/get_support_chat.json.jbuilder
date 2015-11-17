json.chat_messages(@messages) do |message|
  json.id message.id
  json.support_issue_id message.support_issue_id
  json.user_id message.user_id
  json.user_name message.support_issue.user.try(:name)
  json.chat_message message.message
  json.created_at message.created_at
end