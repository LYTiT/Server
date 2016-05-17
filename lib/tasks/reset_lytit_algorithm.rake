namespace :lytit do

  desc "called by Heroku scheduler in order to reset variables and LYTiT bar position every day at 6am"
  task :reset_algorithm => :environment do
    puts "Reseting Lytit..."

    #LytitBar.instance.update_columns(position: 0)
    #puts 'bar position set to 0'

#    LytitVote.delete_all
#    puts 'cleared votes'

    #delete Instagrams, Meta Data, Feed Activity and Notifications older than a day old
    #VenueComment.where("content_origin = ? AND (NOW() - created_at) >= INTERVAL '1 DAY'", 'instagram').destroy_all
    

    #Daily cleanup
    Tweet.where("(NOW() - created_at) >= INTERVAL '1 DAY'").delete_all
    Notification.where({created_at: {"$lte": (Time.now-1.day)}}).delete_all
    InstagramVortex.stale_vortex_check


    VenueComment.cleanup_and_recalibration
    #Venue.cleanup_and_calibration
    FeedRecommendation.set_daily_spotlyt

    #Pull events for primary cities
    Event.focus_cities_pull

    #Set lower bound on Tweet id pull
    Tweet.set_daily_tweet_id

    #Reset number of new moments for favorite venues of users if necessary
    FavoriteVenue.num_new_moment_reset

    Venue.database_cleanup(3)
    PostPass.where("created < ?", Time.now-24.hours).delete_all

    puts "done."
  end  

end