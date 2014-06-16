namespace :lytit do

  desc "called by Heroku scheduler in order to reset variables and LYTiT bar position every day at 6am"
  task :reset_algorithm => :environment do
    puts "Reseting LYTiT..."

    LytitBar.instance.position = 0
    puts 'bar position set to 0'

    LytitVote.delete_all
    puts 'cleared votes'

    Venue.all.each do |venue|
      venue.reset_r_vector
    end

    puts "done."
  end

end