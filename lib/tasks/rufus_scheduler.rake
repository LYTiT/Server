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

    $scheduler.every '1h' do
      Activity.feature_venue_cleanup
      VenueComment.cleanup_and_recalibration
      Venue.where("latest_posted_comment_time <= ?", Time.now - 24.hours).update_all(tag_1: nil, tag_2: nil, tag_3: nil, tag_4: nil, tag_5: nil)
      Venue.cleanup_and_calibration
    end

    #Instagram Pulling and LYT Updating ------------------------------>
    $scheduler.every '10m' do
      puts "Scheduler run at #{Time.now}"
      start_time = Time.now

      puts "Pulling from Instagram"
      vortexes = InstagramVortex.where("active = ?", true)
      for vortex in vortexes
        puts "Entered vortex #{vortex.details}"
        vortex.update_columns(last_instagram_pull_time: Time.now)
        new_instagrams = Instagram.media_search(vortex.latitude, vortex.longitude, :distance => vortex.pull_radius, :count => 1000)
        new_instagrams.each do |instagram|
          VenueComment.create_vc_from_instagram(instagram.to_hash, nil, vortex, true)
        end
        vortex.move
        #if there are multiple vortexes in a city we traverse through them to save instagram API calls
        if vortex.vortex_group_que != nil
          vortex.update_columns(active: false)
          next_city_vortex = InstagramVortex.where("vortex_group = ? AND vortex_group_que = ?", vortex.vortex_group, vortex.vortex_group_que+1).first
          #if vortex is the last in que (no vortex exists with vortex_group_que+1) activate the first vortex in the city
          if next_city_vortex == nil
            next_city_vortex = InstagramVortex.where("vortex_group = ? AND vortex_group_que = ?", vortex.vortex_group, 1).first
          end
          next_city_vortex.update_columns(active: true)
        end
      end

      puts("Recalculating color ratings")
      spheres = LytSphere.uniq.pluck(:sphere)

      for sphere in spheres
        Venue.update_venue_ratings_in(sphere)
      end
      end_time = Time.now
      puts "Done. Time Taken: #{end_time - start_time}s"
    end
    
    #Cluster clearing ----------------------------------->
    $scheduler.every '5m' do
      puts "Scheduler run at #{Time.now}"
      start_time = Time.now

      puts "Clearing clusters"
      ClusterTracker.delete_all
      end_time = Time.now
      puts "Done. Time Taken: #{end_time - start_time}s"
    end

    $scheduler.join
  end

  trap "TERM" do                             
    puts "SIGTERM Received. Shutting down scheduler."                
    $scheduler.shutdown(:wait)
    exit
  end   

end