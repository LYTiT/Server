require 'rufus-scheduler'

namespace :lytit do

  desc "Scheduled Task for LYTiT"
  task :scheduler => :environment do
    $scheduler = Rufus::Scheduler.singleton

    #Heroku restart every 18 hours------------------->
    $scheduler.every '18h' do
      puts "Restarting Heroku Dynos"
      #Heroku::API.new(:api_key => 'bad9f90f-2bd6-47b7-a392-b06a06667933').post_ps_restart('lytit-bolt')
    end

    $scheduler.every '3h' do
      puts "Venue Comment Cleanup"
      VenueComment.cleanup_and_recalibration
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
        for instagram in new_instagrams
          VenueComment.create_vc_from_instagram(instagram.to_hash, nil, vortex)
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

      for entry in spheres
        sphericles = Venue.where("id IN (?)", LytSphere.where(:sphere => entry).pluck(:venue_id)).to_a

        diff_ratings = Set.new
        for venue in sphericles
          if venue.latest_rating_update_time != nil and venue.latest_rating_update_time < Time.now - 10.minutes
            venue.update_rating()
            venue.update_popularity_rank
          end
          
          if venue.is_visible? == true #venue.rating != nil && venue.rating > 0.0 
            if venue.rating != nil
              rat = venue.rating.round(2)
              diff_ratings.add(rat)
            end
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
          #VenueColorRating.create({
          #  :venue_id => venue.id,
          #  :color_rating => colors_map[rating]
          #})

        end
      end
      end_time = Time.now
      puts "Done. Time Taken: #{end_time - start_time}s"
    end
    
    #Trending Updating ----------------------------------->
    $scheduler.every '5m' do
      puts "Scheduler run at #{Time.now}"
      start_time = Time.now
      
      #bar = LytitBar.instance
      #bar.recalculate_bar_position
      #puts 'Bar updated'

      puts "Clearing clusters"
      ClusterTracker.delete_all

=begin
      puts "Recalculating trending indices"

      #used for determing which way top venues are trending
      Venue.where("popularity_rank IS NOT NULL").order("popularity_rank desc limit 10").each_with_index do |venue, index|
        venue.update_columns(trend_position: index)
      end

      total_popular_venues = Venue.where("popularity_rank IS NOT NULL").count
      if total_popular_venues > 10
        Venue.where("popularity_rank IS NOT NULL").order("popularity_rank asc limit #{total_popular_venues-10}").update_all(trend_position: nil)
        Venue.where("popularity_rank IS NOT NULL").order("popularity_rank asc limit #{total_popular_venues-10}").update_all(popularity_rank: 0.0)
      end

      Rails.cache.fetch(:get_trending_venues, :expires_in => 5.minutes) do
        Venue.order("popularity_rank desc limit 10").includes(:venue_comments)
      end
=end

      #set image previews for spotlyts
      puts "Setting Spotlyt image thumbnail preview"
      spotlyts = FeedRecommendation.where("spotlyt IS TRUE AND ACTIVE IS TRUE").includes(:feed)
      spotlyts.each{|spotlyt| spotlyt.set_image_url}

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