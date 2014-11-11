# This is a replacement for Rufus Scheduler on Dev & Prod. 
# To save a worker, we just run a one off dyno every 10 mins
# NOTE: DO NOT SCHEDULE THIS ON PRODUCTION

namespace :lytit do

  desc "Called by Heroku Scheduler in order to recalculate color values every 10m"
  task :refresh_colors => :environment do
    
    puts "Scheduler run at #{Time.now}"

    start_time = Time.now
    
    bar = LytitBar.instance
    bar.recalculate_bar_position
    puts 'Bar updated'

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

    Venue.update_all(color_rating: -1.0)


    for entry in spheres
      sphericles = Venue.where("id IN (?)", LytSphere.where(:sphere => entry).pluck(:venue_id)).to_a

      diff_ratings = Set.new
      for venue in sphericles
        venue.update_rating()
        if venue.is_visible? #venue.rating != nil && venue.rating > 0.0
          rat = venue.rating.round(2)
          diff_ratings.add(rat)
        else
          #venues.delete(venue)
          sphericles.delete(venue)
          LytSphere.where("venue_id = ?", venue.id).delete_all
        end
      end

      diff_ratings = diff_ratings.to_a.sort
      step = 1.0 / (diff_ratings.size - 1)
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