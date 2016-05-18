require 'rufus-scheduler'

namespace :lytit do

  desc "Scheduled Task for LYTiT"
  task :scheduler => :environment do
    $scheduler = Rufus::Scheduler.singleton

    #Heroku restart every 18 hours------------------->
    #$scheduler.every '18h' do
      #puts "Restarting Heroku Dynos"
      #Heroku::API.new(:api_key => 'bad9f90f-2bd6-47b7-a392-b06a06667933').post_ps_restart('lytit-bolt')
    #end

    #Instagram Pulling and LYT Updating ------------------------------>
    $scheduler.every '5m' do
      puts "Scheduler run at #{Time.now}"
      start_time = Time.now

      puts "Pulling from Instagram"
      InstagramVortex.global_pull

      puts("Recalculating color ratings")
      #spheres = LytSphere.uniq.pluck(:sphere)

      Venue.update_all_active_venue_ratings
      #for sphere in spheres
      #  Venue.update_venue_ratings_in(sphere)
      #end
      end_time = Time.now
      puts "Done. Time Taken: #{end_time - start_time}s"
    end
    
    #Cluster clearing ----------------------------------->
    $scheduler.every '10m' do
      puts "Scheduler run at #{Time.now}"
      start_time = Time.now
      puts "Setting Top Tags"
      Venue.each{|venue| venue.set_top_tags}
      end_time = Time.now
      puts "Done. Time Taken: #{end_time - start_time}s"
    end

    $scheduler.every '30m' do
      puts "Clearing expired Post Passes"
      puts "Scheduler run at #{Time.now}"
      PostPass.where("created_at < ?", Time.now-30.minutes).delete_all
    end

    $scheduler.every '1h' do
      Activity.feature_venue_cleanup
      VenueComment.cleanup_and_recalibration
      Venue.where("latest_posted_comment_time <= ?", Time.now - 24.hours).update_all(tag_1: nil, tag_2: nil, tag_3: nil, tag_4: nil, tag_5: nil)
      #Venue.cleanup_and_calibration
    end



    $scheduler.join
  end

  trap "TERM" do                             
    puts "SIGTERM Received. Shutting down scheduler."                
    $scheduler.shutdown(:wait)
    exit
  end   

end