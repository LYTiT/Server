class LumenGameWinner < ActiveRecord::Base
  belongs_to :user

  def new_winner_notification
  	message = "Congratulations #{user.name}, you are a winner in this month's Lumen Game! 
    Please validate your student email through the link which we have sent you. 
    After that you will be able to enter your PayPal info below and receive your $100. 
    If issues arise reach out to support@lytit.com."
  	congratulations = Announcement.new(news: message,  title: "You Are a Winner!")
  	congratulations.save
  	recipient = AnnouncementUser.new(user_id: id, announcement_id: congratulations.id)
  	recipient.save
  	arr = []<<user
  	congratulations.send_new_announcement(arr, self.id)
  end


end