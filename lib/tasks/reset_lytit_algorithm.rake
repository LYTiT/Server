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

    puts "done."
  end

end