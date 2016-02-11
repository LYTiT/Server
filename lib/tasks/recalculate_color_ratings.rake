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
      #if there are multiple vortexes in a city we traverse through them to save instagram API calls
      if vortex.group_que != nil
        vortex.update_columns(active: false)
        next_city_vortex = InstagramVortex.where("group = ? AND group_que = ?", vortex.group, vortex.group_que+1).first
        #if vortex is the last in que (no vortex exists with group_que+1) activate the first vortex in the city
        if next_city_vortex == nil
          next_city_vortex = InstagramVortex.where("group = ? AND group_que = ?", vortex.group, 1).first
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
    Venue.where("popularity_rank IS NOT NULL").order("popularity_rank desc limit 10").each_with_index do |venue, index|
      venue.update_columns(trend_position: index)
    end 

    Venue.where("popularity_rank IS NOT NULL").order("popularity_rank asc limit #{Venue.where("popularity_rank IS NOT NULL").count-10}").update_all(trend_position: nil)
    
    for entry in spheres
      sphericles = Venue.where("id IN (?)", LytSphere.where(:sphere => entry).pluck(:venue_id)).to_a

      diff_ratings = Set.new
      for venue in sphericles
        venue.update_rating()
        venue.update_popularity_rank
        if venue.is_visible? == true #venue.rating != nil && venue.rating > 0.0
          rat = venue.rating.round(2)
          diff_ratings.add(rat)
        else
          #venues.delete(venue)
          sphericles.delete(venue)
          LytSphere.where("venue_id = ?", venue.id).delete_all
        end
      end

      diff_ratings = diff_ratings.to_a.sort
      if diff_ratings.size == 1
        step = 0.0
      else
        step = 1.0 / (diff_ratings.size - 1)
      end
      colors_map = {0.0 => 0.0}
      color = -step

      for rating in diff_ratings
        color += step
        colors_map[rating] = color.round(2)
      end

      for venue in sphericles
        rating = venue.rating ? venue.rating.round(2) : 0.0
        venue.update_columns(color_rating: colors_map[rating])
      end

    end

    #reset_lytit_algo runs only in production so to clear 24 hour Venue Comments we use the work around below 
    if Time.now.hour == 23 && Time.now.min > 30
      VenueComment.where("content_origin = ? AND (NOW() - created_at) >= INTERVAL '1 DAY'", 'instagram').delete_all
      MetaData.where("(NOW() - created_at) >= INTERVAL '1 DAY'").delete_all
      Activity.where("(NOW() - created_at) >= INTERVAL '1 DAY'").delete_all
      Notification.where({created_at: {"$lte": (Time.now-1.day)}}).delete_all
    end

    #set image previews for spotlyts
    spotlyts = FeedRecommendation.where("spotlyt IS TRUE AND ACTIVE IS TRUE").includes(:feed)
    spotlyts.each{|spotlyt| spotlyt.set_image_url}

    end_time = Time.now

    puts "Done. Time Taken: #{end_time - start_time}s"

  end

end