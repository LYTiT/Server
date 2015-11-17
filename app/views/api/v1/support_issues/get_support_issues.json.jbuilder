json.chat_messages(@issues) do |issue|
  json.support_issue_id issue.id
  json.user_id issue.user_id
  json.user_name issue.user.try(:name)
  json.chat_message issue.support_messages.order("id DESC").first.message
  json.created_at issue.support_messages.order("id DESC").first.created_at
end