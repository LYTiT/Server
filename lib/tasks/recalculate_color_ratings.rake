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
    vortexes = InstagramVortex.where("active = ?", true)
    for vortex in vortexes
      puts "Entered vortex #{vortex.description}"
      vortex.update_columns(last_instagram_pull_time: Time.now)
      new_instagrams = Instagram.media_search(vortex.latitude, vortex.longitude, :distance => vortex.pull_radius, :count => 1000)
      for instagram in new_instagrams
        VenueComment.convert_instagram_to_vc(instagram)
      end
      #if there are multiple vortexes in a city we traverse through them to save instagram API calls
      if vortex.city_que != nil
        vortex.update_columns(active: nil)
        next_city_vortex = InstagramVortex.where("city = ? AND city_que = ?", vortex.city, vortex.city_que+1)
        #if vortex is the last in que (no vortex exists with city_que+1) activate the first vortex in the city
        if next_city_vortex == nil
          next_city_vortex = InstagramVortex.where("city = ? AND city_que = ?", vortex.city, 1)
        end
          next_city_vortex.update_columns(active: true)
          vortex.update_columns(active: false)
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

    puts "Recalculating venue colors"

    #Venue.update_all(color_rating: -1.0)

    for entry in spheres
      sphericles = Venue.where("id IN (?)", LytSphere.where(:sphere => entry).pluck(:venue_id)).to_a

      diff_ratings = Set.new
      for venue in sphericles
        venue.update_rating()
        if venue.is_visible? #venue.rating != nil && venue.rating > 0.0
          rat = venue.rating.round(3)
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
        VenueColorRating.create({
          :venue_id => venue.id,
          :color_rating => colors_map[rating]
        })
      end

    end

    end_time = Time.now

    puts "Done. Time Taken: #{end_time - start_time}s"

  end

end