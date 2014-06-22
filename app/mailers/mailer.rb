class Mailer < ActionMailer::Base
  
  def welcome_venue_manager(user)
    @user = user
    mail(
      to: @user.email, 
      subject: 'Welcome to LYTiT Venue Manager'
    )
  end

  def welcome_user(user)
    @user = user
    mail(
      to: @user.email, 
      subject: 'Welcome to LYTiT'
    )
  end

end
