require 'rufus-scheduler'

namespace :lytit do

  desc "Scheduled Task for LYTiT"
  task :scheduler => :environment do
    $scheduler = Rufus::Scheduler.singleton
    
    $scheduler.every '5m' do

      puts "Scheduler run at #{Time.now}"

      start_time = Time.now
      
      bar = LytitBar.instance
      bar.recalculate_bar_position
      puts 'Bar updated'

      venues = Venue.visible

      puts "Recaculating venue ratings..."
      for venue in venues
        venue.update_rating()
      end
      puts "Done."

      puts "Recalculating venue colors"

      Venue.update_all(color_rating: -1.0)


    ###needs by city
      diff_ratings = Set.new
      for venue in venues
        if venue.rating != nil && venue.rating > 0.0
          rat = venue.rating.round(2)
          diff_ratings.add(rat)
        else
          venues.delete(venue)
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

      for venue in venues
        rating = venue.rating ? venue.rating.round(2) : 0.0
        venue.update_columns(color_rating: colors_map[rating])
        VenueColorRating.create({
          :venue_id => venue.id,
          :color_rating => colors_map[rating]
        })
      end
    ###

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