namespace :lytit do

  desc "called by Heroku scheduler in order to recalculate color values every 15m"
  task :refresh_colors => :environment do
    puts "Recalculating venue colors..."

    Venue.update_all(color_rating: -1.0)

    # visible venues are those which had been voted in the last 3.5 hours
    venues = Venue.visible

    diff_ratings = Set.new
    for venue in venues
      if venue.rating
        rat = venue.rating.round(2)
        diff_ratings.add(rat)
      end
    end

    diff_ratings = diff_ratings.to_a.sort

    step = 1.0 / (diff_ratings.size - 1)

    colors_map = {0.0 => 0.0} # null ratings will be out of the distribution range, just zero
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
    
    puts "done."
  end

end