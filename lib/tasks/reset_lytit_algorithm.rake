namespace :lytit do

  desc "called by Heroku scheduler in order to reset variables and LYTiT bar position every day at 6am"
  task :reset_algorithm => :environment do
    puts "Reseting LYTiT..."
    #Venue.all.each do |venue|
    #  venue.reset_rating_vectors
    #  venue.save
    #end

    LytitBar.instance.position = 0

    puts "done."
  end

end