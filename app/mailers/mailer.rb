class Mailer < ActionMailer::Base
  layout 'mailer'

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

  def email_validation(user)
    @user = user
    mail(
      to: @user.email, 
      subject: 'Congratulations from Team LYTiT!'
    )
  end

  def new_support_message(help_requester, message)
    @user = help_requester
    @message = message
    admin_emails = ["leonid@lytit.com", "tim@lytit.com", "support@lytit.com"]
    for email in admin_emails
      mail(
        to: email, 
        subject: 'In-App Support Assitance Needed'
      )
    end
  end

  def notify_admins_of_monthly_winners(user)
    @user = user
    @winners = LumenGameWinner.where("email_sent = TRUE AND created_at >= ?", (Time.now-1.day).beginning_of_month)
    mail(
      to: @user.email, 
      subject: 'Monthly Lumen Game Winners Have Been Selected'
    )
  end

  def notify_admins_of_user_paypal_details(admin, winner)
    @user = admin
    @winner = winner
    mail(
      to: @user.email, 
      subject: 'A Winner Has Submitted Paypal Details'
    )
  end
end
