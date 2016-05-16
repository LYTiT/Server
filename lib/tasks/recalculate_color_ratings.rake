# This is a replacement for Rufus Scheduler on Dev & Prod. 
# To save a worker, we just run a one off dyno every 10 mins
# NOTE: DO NOT SCHEDULE THIS ON PRODUCTION

namespace :lytit do

  desc "Called by Heroku Scheduler in order to recalculate color values every 10m"
  task :refresh_colors => :environment do
    
    puts "Scheduler run at #{Time.now}"
    start_time = Time.now


    #Instagram data pull----------->

    puts "Pulling from Instagram"
    InstagramVortex.global_pull

    #LYT Updating------------------>
    Venue.update_all_active_venue_ratings

    CommentView.assign_views


    #reset_lytit_algo runs only in production so to clear 24 hour Venue Comments we use the work around below 
    if Time.now.hour == 23 && Time.now.min > 30
      Event.focus_cities_pull
      VenueComment.where("content_origin = ? AND (NOW() - created_at) >= INTERVAL '1 DAY'", 'instagram').delete_all
      MetaData.where("(NOW() - created_at) >= INTERVAL '1 DAY'").delete_all
      #Activity.where("(NOW() - created_at) >= INTERVAL '1 DAY'").delete_all
      Notification.where({created_at: {"$lte": (Time.now-1.day)}}).delete_all
      #Tweet.set_daily_tweet_id
    end

    end_time = Time.now

    Tweet.set_daily_tweet_id
    
    puts "Done. Time Taken: #{end_time - start_time}s"

  end

end