class Api::V1::VenuesController < ApiBaseController

	skip_before_filter :set_user, only: [:search, :index]


	def show
		@user = User.find_by_authentication_token(params[:auth_token])
		@venue = Venue.find(params[:id])		
		venue = @venue.as_json(include: :venue_messages)

		venue[:compare_type] = @venue.type

		render json: venue
	end

	def get_menue
		@venue = Venue.find(params[:id])
	end

	def delete_comment
		vc = VenueComment.find_by_id(params[:id])
		vc.destroy
		render json: { success: true }
	end

	def report_comment
		if FlaggedComment.where("user_id = ? AND venue_comment_id = ? AND message = ?", @user.id, params[:comment_id], params[:message]).any? == false
			venue_comment = VenueComment.find(params[:comment_id])
			fc = FlaggedComment.new
			fc.user_id = @user.id
			fc.message = params[:message]
			fc.venue_comment_id = venue_comment.id
			fc.save
			render json: fc
		end
	end

	def get_comments
		#register feed open
		@user = User.find_by_authentication_token(params[:auth_token])
		feeduser = FeedUser.where("user_id = ? AND feed_id = ?", @user.id, params[:feed_id]).first
		if feeduser != nil
			feeduser.update_columns(last_visit: Time.now)
		end
		
		venue_ids = params[:cluster_venue_ids].split(',').map(&:to_i)

		if not venue_ids 
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["Venue(s) not found"] } }, :status => :not_found
		else
			if venue_ids.count == 1
				@venue = Venue.find_by_id(venue_ids.first)
				@venue.delay.account_page_view
				cache_key = "venue/#{venue_ids.first}/comments/page#{params[:page]}"
			else
				cache_key = "cluster/cluster_#{venue_ids.length}_#{params[:cluster_latitude]},#{params[:cluster_longitude]}/comments/page#{params[:page]}"
			end
			@view_cache_key = cache_key+"view"
			@comments = Rails.cache.fetch(cache_key, :expires_in => 3.minutes) do
				Venue.get_comments(venue_ids).limit(10).offset((params[:page].to_i-1)*10)
			end
		end
	end

	def get_comments_implicitly
		if params[:country] != nil
			@venue = Venue.fetch(params[:name], params[:formatted_address], params[:city], params[:state], params[:country], params[:postal_code], params[:phone_number], params[:latitude], params[:longitude])
			#Venue.fetch(params["name"], params["formatted_address"], params["city"], params["state"], params["country"], params["postal_code"], params["phone_number"], params["latitude"], params["longitude"])
		else
			@venue = Venue.fetch_venues_for_instagram_pull(params[:name], params[:latitude].to_f, params[:longitude].to_f, params[:instagram_location_id])
		end

		if params[:meta_query] != nil
			@comments = VenueComment.meta_search_results(@venue.id, params[:meta_query]).page(params[:page]).per(10)
			render 'meta_search_comments.json.jbuilder'
		else
			if @venue.instagram_location_id == nil
				initial_instagrams = @venue.set_instagram_location_id(100)
				@venue.delay.account_page_view
			end

			if initial_instagrams != nil
				live_comments = Kaminari.paginate_array(initial_instagrams)
			else
				live_comments = Venue.get_comments([@venue.id])	
			end

			@comments = live_comments.page(params[:page]).per(10)
		end
	end

	def get_venue_feeds
		@user = User.find_by_authentication_token(params[:auth_token])
		@feeds = Feed.feeds_in_venue(params[:venue_id])
	end

	def get_cluster_feeds
		@user = User.find_by_authentication_token(params[:auth_token])
		@feeds = Feed.feeds_in_cluster(params[:cluster_venue_ids]).page(params[:page]).per(10)
	end

	def get_tweets
		venue_ids = params[:cluster_venue_ids].split(',')
		cluster_lat = params[:cluster_latitude]
		cluster_long =  params[:cluster_longitude]
		zoom_level = params[:zoom_level]
		map_scale = params[:map_scale]

		
		if venue_ids.count == 1
			@venue = Venue.find_by_id(venue_ids.first)		
			cache_key = "venue/#{venue_ids.first}/tweets/page#{params[:page]}"
			
			#venue_tweets = @venue.venue_twitter_tweets
			#@tweets = venue_tweets.page(params[:page]).per(10)
		else
			cache_key = "cluster/cluster_#{venue_ids.length}_#{params[:cluster_latitude]},#{params[:cluster_longitude]}/tweets/page#{params[:page]}"	
			#cluster_tweets = Venue.cluster_twitter_tweets(cluster_lat, cluster_long, zoom_level, map_scale, params[:cluster_venue_ids])
			#@tweets = cluster_tweets.page(params[:page]).per(10)
		end

		@tweets = Rails.cache.fetch(cache_key, :expires_in => 3.minutes) do
			if venue_ids.count == 1
				@venue.venue_twitter_tweets.limit(10).offset((params[:page].to_i-1)*10)
			else
				Venue.cluster_twitter_tweets(cluster_lat, cluster_long, zoom_level, map_scale, params[:cluster_venue_ids]).offset((params[:page].to_i-1)*10)
			end
		end

	end

	def get_surrounding_tweets
		venue_ids = params[:cluster_venue_ids].split(',')
		lat = params[:latitude]
		long =  params[:longitude]
		zoom_level = params[:zoom_level]
		map_scale = params[:map_scale]
		fresh_pull = params[:fresh_pull]

		@user = User.find_by_authentication_token(params[:auth_token])

		if fresh_pull == "0"
			surrounding_tweets = Rails.cache.fetch("surrounding_tweets/#{@user.id}", :expires_in => 5.minutes) do
				Venue.surrounding_twitter_tweets(lat, long, params[:cluster_venue_ids])
			end
		else
			begin
				Rails.cache.delete("surrounding_tweets/#{@user.id}")
			rescue
				puts "No cache present to delete"
			end
			surrounding_tweets = Venue.surrounding_twitter_tweets(lat, long, params[:cluster_venue_ids])
		end
		
		@tweets = Kaminari.paginate_array(surrounding_tweets).page(params[:page]).per(10)
	end

	def mark_comment_as_viewed
		@user = User.find_by_authentication_token(params[:auth_token])
		@comment = VenueComment.find_by_id(params[:post_id])

		#consider is used for Lumen calculation. Initially it is set to 2 for comments with no views and then is
		#updated to the true value (1 or 0) for a particular comment after a view (comments with no views aren't considered
		#for Lumen calcuation by default)

		if (@comment.is_viewed?(@user) == false) #and (@comment.user_id != @user.id)
			@comment.update_views
			poster = @comment.user
			if poster != nil
				poster.update_total_views
				if poster.id != @user.id
					@comment.calculate_adj_view
					if @comment.consider? == 1 
						poster.update_lumens_after_view(@comment)
					end
				end
			end
		end

		if @comment.present?
				comment_view = CommentView.new
				comment_view.user = @user
				comment_view.venue_comment = @comment
				comment_view.save
		else
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["Venue / Post not found"] } }, :status => :not_found
			return
		end
	end

	def refresh_map_view
		Venue.delay.instagram_content_pull(params[:latitude], params[:longitude])
		cache_key = "lyt_map"
		@view_cache_key = cache_key+"/view"
		@venues = Rails.cache.fetch(cache_key, :expires_in => 5.minutes) do
			Venue.where("color_rating > -1.0")
		end
		render 'display.json.jbuilder'
	end

	def refresh_map_view_by_parts
		lat = params[:latitude] || 40.741140
		long = params[:longitude] || -73.981917

		if params[:page] == 1
			num_page_entries = 500
		else
			num_page_entries = 1000
		end

		cache_key = "lyt_map_by_parts"
		venues = Rails.cache.fetch(cache_key, :expires_in => 5.minutes) do
			Venue.all.where("color_rating > -1.0")
		end

		ordered_venues = venues.order("(ACOS(least(1,COS(RADIANS(#{lat}))*COS(RADIANS(#{long}))*COS(RADIANS(venues.latitude))*COS(RADIANS(venues.longitude))+COS(RADIANS(#{lat}))*SIN(RADIANS(#{long}))*COS(RADIANS(venues.latitude))*SIN(RADIANS(venues.longitude))+SIN(RADIANS(#{lat}))*SIN(RADIANS(venues.latitude))))*6376.77271) ASC")
		user_city = ordered_venues.first.city || ordered_venues[1].city || ordered_venues[2].city || ordered_venues[3].city || ordered_venues[4].city
		@view_cache_key = cache_key+"/#{user_city}/part_"+params[:page]

		@venues = ordered_venues.page(params[:page]).per(num_page_entries)
		render 'display_by_parts.json.jbuilder'
	end

	def search
		@user = User.find_by_authentication_token(params[:auth_token])

		if params[:instagram_location_id] == nil
			venue = Venue.fetch(params[:name], params[:formatted_address], params[:city], params[:state], params[:country], params[:postal_code], params[:phone_number], params[:latitude], params[:longitude])
			@venues = [venue]
		else
			@venues =[Venue.fetch_venues_for_instagram_pull(params[:name], params[:latitude], params[:longitude], params[:instagram_location_id])]
		end

		render 'search.json.jbuilder'
	end

	def direct_fetch
		position_lat = params[:latitude]
		position_long = params[:longitude]

		ne_lat = params[:ne_latitude]
		ne_long = params[:ne_longitude]
		sw_lat = params[:sw_latitude]
		sw_long = params[:sw_longitude]

		query = params[:q]

		@venues = Venue.direct_fetch(query, position_lat, position_long, ne_lat, ne_long, sw_lat, sw_long).to_a

		render 'search.json.jbuilder'
	end

	def get_suggested_venues
		@user = User.find_by_authentication_token(params[:auth_token])
		@suggestions = Venue.near_locations(params[:latitude], params[:longitude])
		render 'get_suggested_venues.json.jbuilder'
	end

	def meta_search
		lat = params[:latitude]
		long = params[:longitude]
		sw_lat = params[:sw_latitude]
		sw_long = params[:sw_longitude]
		ne_lat = params[:ne_latitude]
		ne_long = params[:ne_longitude]
		
		#Cleaning the search term
		query = params[:q].downcase.gsub(" ","").gsub(/[^0-9A-Za-z]/, '')
		junk_words = ["the", "their", "there", "yes", "you", "are", "when", "why", "what", "lets", "this", "got", "put", "such", "much", "ask", "with", "where", "each", "all", "from", "bad", "not", "for", "our"]
		junk_words.each{|word| query.gsub!(word, "")}

		#Plurals singularized for searching purposes (ie "dogs" returns the same things as "dog")
		if query.length > 3
			if (query.last(3) != "ies" && query.last(1) == "s") 
				query = query[0...-1]
			end
			if (query.last(3) == "ies")
				query = query[0...-3]
			end
		end

		if query.length > 2
			num_page_entries = 12
			page = params[:page].to_i

			crude_results = VenueComment.meta_search(query, lat, long, sw_lat, sw_long, ne_lat, ne_long)
			page_results = crude_results[ (page-1)*num_page_entries .. (page-1)*num_page_entries+(num_page_entries-1) ]

			previous_results = [params[:previous_id_1], params[:previous_id_2], params[:previous_id_3], params[:previous_id_4], params[:previous_id_5], params[:previous_id_6], params[:previous_id_7], params[:previous_id_8], params[:previous_id_9], params[:previous_id_10], params[:previous_id_11], params[:previous_id_12], params[:previous_id_13], params[:previous_id_14], params[:previous_id_15], params[:previous_id_16], params[:previous_id_17], params[:previous_id_18], params[:previous_id_19], params[:previous_id_20], params[:previous_id_21], params[:previous_id_22], params[:previous_id_23], params[:previous_id_24], params[:previous_id_25], params[:previous_id_26], params[:previous_id_27], params[:previous_id_28], params[:previous_id_29], params[:previous_id_30], params[:previous_id_31], params[:previous_id_32], params[:previous_id_33], params[:previous_id_34], params[:previous_id_35], params[:previous_id_36]]

			if page_results != nil
				for result in page_results
					if result != nil and (result.meta_search_sanity_check(query) == false || previous_results.include?(result.id.to_s) == true)
						page_results.delete(result)
					end
				end

				if page_results.count != num_page_entries
					pos = page * num_page_entries
					while (page_results.count < num_page_entries && pos < crude_results.count) do
						filler = crude_results[pos]
						if filler != nil and (filler.meta_search_sanity_check(query) == true && previous_results.include?(filler.id.to_s) == false)
							page_results << filler
						end
						pos = pos + 1
					end
				end
			end

			crude_results_paginated = Kaminari.paginate_array(crude_results)
			@page_tracker = crude_results_paginated.page(page).per(num_page_entries)
			@comments = page_results
		else
			@comments = nil
		end
	end

	def get_trending_venues 
		@venues = Rails.cache.fetch(:get_trending_venues, :expires_in => 5.minutes) do
			Venue.where("trend_position IS NOT NULL").order("trend_position ASC limit 10").includes(:venue_comments)
		end
	end

	def get_trending_venues_details
		@venues = Rails.cache.fetch(:get_trending_venues, :expires_in => 5.minutes) do
			Venue.where("trend_position IS NOT NULL").order("trend_position ASC limit 10").includes(:venue_comments)
		end		
	end

	def get_contexts
		#Hanlding both for individual venue and clusters.
		if params[:cluster_venue_ids] != nil
			@contexts = MetaData.cluster_top_meta_tags(params[:cluster_venue_ids])
			@key = "contexts/cluster/#{params[:cluster_venue_ids].first(10)}_#{params[:cluster_venue_ids].length}"
			render 'get_cluster_contexts.json.jbuilder'
		else
			@venue = Venue.find_by_id(params[:venue_id])
			@key = "contexts/venue/#{params[:venue_id]}"

			@contexts = Rails.cache.fetch(@key, :expires_in => 3.minutes) do
				MetaData.where("(NOW() - created_at) <= INTERVAL '1 DAY' AND venue_id = ?", params[:venue_id]).order("relevance_score DESC LIMIT 5")
			end

			MetaData.delay.bulck_relevance_score_update(@contexts)
			render 'get_contexts.json.jbuilder'
		end
	end

	def explore_venues
		user_lat = params[:latitude]
		user_long = params[:longitude]

		nearby_radius = 5000.0 * 1/1000 #* 0.000621371 #meters to miles
		rand_position = Random.rand(20)

		if params[:proximity] == "nearby"
			@venue = Venue.where("(ACOS(least(1,COS(RADIANS(#{user_lat}))*COS(RADIANS(#{user_long}))*COS(RADIANS(latitude))*COS(RADIANS(longitude))+COS(RADIANS(#{user_lat}))*SIN(RADIANS(#{user_long}))*COS(RADIANS(latitude))*SIN(RADIANS(longitude))+SIN(RADIANS(#{user_lat}))*SIN(RADIANS(latitude))))*6376.77271) 
        <= #{nearby_radius}").order("popularity_rank DESC").limit(20)[rand_position]
		else
			@venue = Venue.where("(ACOS(least(1,COS(RADIANS(#{user_lat}))*COS(RADIANS(#{user_long}))*COS(RADIANS(latitude))*COS(RADIANS(longitude))+COS(RADIANS(#{user_lat}))*SIN(RADIANS(#{user_long}))*COS(RADIANS(latitude))*SIN(RADIANS(longitude))+SIN(RADIANS(#{user_lat}))*SIN(RADIANS(latitude))))*6376.77271) 
        > #{nearby_radius}").order("popularity_rank DESC").limit(50)[rand_position]
		end
	end

	def get_latest_tweet
		venue_ids = params[:cluster_venue_ids].split(",")
		cluster_lat = params[:cluster_latitude]
		cluster_long =  params[:cluster_longitude]
		zoom_level = params[:zoom_level]
		map_scale = params[:map_scale]

		radius = 160.0 * 1/1000

		if venue_ids.count == 1
			venue = Venue.find_by_id(venue_ids.first)
			@tweet = Tweet.where("venue_id = ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", venue.id).order("timestamp DESC").order("popularity_score DESC LIMIT 1")[0]
			venue.delay.pull_twitter_tweets
		else
			cluster = ClusterTracker.check_existence(cluster_lat, cluster_long, zoom_level)
			@tweet = Tweet.where("venue_id IN (?) OR (ACOS(least(1,COS(RADIANS(#{cluster_lat}))*COS(RADIANS(#{cluster_long}))*COS(RADIANS(latitude))*COS(RADIANS(longitude))+COS(RADIANS(#{cluster_lat}))*SIN(RADIANS(#{cluster_long}))*COS(RADIANS(latitude))*SIN(RADIANS(longitude))+SIN(RADIANS(#{cluster_lat}))*SIN(RADIANS(latitude))))*6376.77271) 
          <= #{radius} AND associated_zoomlevel <= ? AND (NOW() - created_at) <= INTERVAL '1 DAY'", venue_ids, zoom_level).order("timestamp DESC").order("popularity_score DESC LIMIT 1")[0]
			Venue.delay.cluster_twitter_tweets(cluster_lat, cluster_long, zoom_level, map_scale, cluster, venue_ids)
		end
	end

	def get_quick_venue_overview
		@venue = Venue.find_by_id(params[:venue_id])
	end

	def get_quick_cluster_overview
		venue_ids = params[:cluster_venue_ids].split(',')
		cluster_lat = params[:cluster_latitude]
		cluster_long =  params[:cluster_longitude]
		zoom_level = params[:zoom_level]
		map_scale = params[:map_scale]

		@posts = VenueComment.where("venue_id IN (?)", venue_ids).order("id DESC LIMIT 4")
		@meta = MetaData.where("venue_id IN (?)", venue_ids).order("relevance_score DESC LIMIT 5")
	end

	def get_surrounding_feed_for_user
		lat = params[:latitude]
		long = params[:longitude]
		venue_ids = params[:venue_ids]

		fresh_pull = params[:fresh_pull]

		@user = User.find_by_authentication_token(params[:auth_token])

		if fresh_pull == "0"
			surrounding_posts = Rails.cache.fetch("surrounding_posts/#{@user.id}", :expires_in => 5.minutes) do
				Venue.surrounding_feed(lat, long, venue_ids)
			end
		else
			begin
				Rails.cache.delete("surrounding_posts/#{@user.id}")
			rescue
				puts "No cache present to delete"
			end
			surrounding_posts = Rails.cache.fetch("surrounding_posts/#{@user.id}", :expires_in => 5.minutes) do
				Venue.surrounding_feed(lat, long, venue_ids)
			end
		end
		
		@posts = Kaminari.paginate_array(surrounding_posts).page(params[:page]).per(10)
	end

	def check_vortex_proximity
		InstagramVortex.check_nearby_vortex_existence(params[:latitude], params[:longitude])
		render json: { success: true }
	end


	private

	def venue
		@venue ||= Venue.find(params[:venue_id])
	end

	def venue_comment_params
		params.permit(:comment, :media_type, :media_url, :session)
	end
end
