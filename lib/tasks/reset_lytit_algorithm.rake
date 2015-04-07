namespace :lytit do

  desc "called by Heroku scheduler in order to reset variables and LYTiT bar position every day at 6am"
  task :reset_algorithm => :environment do
    puts "Reseting LYTiT..."

    LytitBar.instance.update_columns(position: 0)
    puts 'bar position set to 0'

#    LytitVote.delete_all
#    puts 'cleared votes'

    Venue.update_all(rating: 0.0)
    Venue.update_all(color_rating: -1.0)
    Venue.all.each do |venue|
      venue.reset_r_vector
    end

    Bounty.all.each do |bounty|
      bounty.check_validity
    end

    yesterday = Time.now - 1.day
    if yesterday.month != (today).month
      final_winners = LumenGameWinner.joins(:user).where("email_confirmed = TRUE").where("lumen_game_winners.created_at >= ?", yesterday.beginning_of_month).sample(50)
      for champ in final_winners
        puts "#{champ.user.name}-#{champ.user.email}"
        champ.user.send_email_validation
        champ.email_sent = true
        champ.save
      end
      founder_1 = User.find_by_email("leonid@lytit.com")
      founder_2 = User.find_by_name("tim@lytit.com")
      Mailer.delay.notify_admins_of_monthly_winners(founder_1)
      Mailer.delay.notify_admins_of_monthly_winners(founder_2)
      puts "Until next month."
    end

    puts "done."
  end

end