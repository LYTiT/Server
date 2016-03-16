# This is a replacement for Rufus Scheduler on Dev & Prod. 
# To save a worker, we just run a one off dyno every 10 mins
# NOTE: DO NOT SCHEDULE THIS ON PRODUCTION

namespace :lytit do

  desc "Called by Heroku Scheduler in order to recalculate color values every 10m"
  task :refresh_colors => :environment do
    
    puts "Scheduler run at #{Time.now}"
    start_time = Time.now

    puts "Clearing clusters"
    ClusterTracker.delete_all

    #Instagram data pull----------->

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

    

    #LYT Updating------------------>
    #bar = LytitBar.instance
    #bar.recalculate_bar_position
    #puts 'Bar updated'

    #venues = Venue.visible
    spheres = LytSphere.uniq.pluck(:sphere)
    #venues = Venue.where("id IN (?)", LytSphere.pluck(:venue_id)).to_a

    #puts "Recaculating venue ratings..."
    #for venue in venues
    #    venue.update_rating()
    #end

    #for venue in venues
    #  venue.update_rating()
    #end

    #puts "Done."

    puts "Recalculating venue colors (on Lumen)"
    
    #used for determing which way top venues are trending
    
    spheres = LytSphere.uniq.pluck(:sphere)

    for sphere in spheres
      Venue.update_venue_ratings_in(sphere)
    end

    ClusterTracker.delete_all

    #reset_lytit_algo runs only in production so to clear 24 hour Venue Comments we use the work around below 
    if Time.now.hour == 23 && Time.now.min > 30
      VenueComment.where("content_origin = ? AND (NOW() - created_at) >= INTERVAL '1 DAY'", 'instagram').delete_all
      MetaData.where("(NOW() - created_at) >= INTERVAL '1 DAY'").delete_all
      #Activity.where("(NOW() - created_at) >= INTERVAL '1 DAY'").delete_all
      Notification.where({created_at: {"$lte": (Time.now-1.day)}}).delete_all
    end

    end_time = Time.now

    puts "Done. Time Taken: #{end_time - start_time}s"

  end

end