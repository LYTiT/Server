class LumenGameWinner < ActiveRecord::Base
  belongs_to :user

  def new_winner_notification
  	message = "Congratulations #{user.name}! You are a winner in this month's Lumen Game!"
  	congratulations = Announcement.new(news: message,  title: "You Are a Winner!")
  	message.save
  	recipient = AnnouncementUser.new(user_id: id, announcement_id: congratulations.id)
  	recipient.save
  	arr = []<<user
  	congratulations.send_new_announcement(arr, self.id)
  end


end