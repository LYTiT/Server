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


    #delete Instagrams, Meta Data, Feed Activity and Notifications older than a day old
    #VenueComment.where("content_origin = ? AND (NOW() - created_at) >= INTERVAL '1 DAY'", 'instagram').destroy_all
    Tweet.where("(NOW() - created_at) >= INTERVAL '1 DAY'").delete_all
    #MetaData.where("(NOW() - created_at) >= INTERVAL '1 DAY'").delete_all
    #Activity.where("(NOW() - created_at) >= INTERVAL '1 DAY'").delete_all
    Notification.where({created_at: {"$lte": (Time.now-1.day)}}).delete_all
    
    #MetaData.where("(NOW() - created_at) > INTERVAL '1 DAY'").delete_all

    #check if vortexes are being used. If not, deactivate them.
    vortexes = InstagramVortex.all

    for vortex in vortexes
        if vortex.last_user_ping < (Time.now-2.days)
            vortex.update_columns(active: false)
        end
    end


    puts "done."
  end

end