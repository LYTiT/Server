if @activity_comment.user_id == @user_id
	json.id @activity_comment.id
	json.chat_message @activity_comment.comment
	json.created_at @activity_comment.created_at
end