namespace :lytit do

  desc "called by Heroku scheduler in order to reset variables and LYTiT bar position every day at 6am"
  task :reset_algorithm => :environment do
    puts "Reseting LYTiT..."

    #LytitBar.instance.update_columns(position: 0)
    #puts 'bar position set to 0'

#    LytitVote.delete_all
#    puts 'cleared votes'

    #Venue.update_all(rating: 0.0)
    #Venue.update_all(color_rating: -1.0)
    #Venue.all.each do |venue|
    #  venue.reset_r_vector
    #end


    #delete Instagrams and corresponding Meta Data daily
    VenueComment.where("content_origin = ? AND (NOW() - created_at) >= INTERVAL '1 DAY'", 'instagram').delete_all
    MetaData.where("(NOW() - created_at) > INTERVAL '1 DAY'").delete_all

    #restart Heroku dynos to clear memory
    #Heroku::API.new(:api_key => 'bad9f90f-2bd6-47b7-a392-b06a06667933').post_ps_restart('lytit-bolt')

    puts "done."
  end

end