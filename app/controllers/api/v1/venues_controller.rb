class Api::V1::VenuesController < ApiBaseController

	skip_before_filter :set_user, only: [:search, :index]

	def show
		@user = User.find_by_authentication_token(params[:auth_token])
		@venue = Venue.find(params[:id])		
		#venue = @venue.as_json(include: :venue_messages)

		#venue[:compare_type] = @venue.type

		render json: venue
	end

	def delete
		if @venue.delete
			render json: { success: true }
		else
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["Venue deleted"] } }, :status => :not_found
		end
	end

	def reset_instagram_id
		@venue.instagram_location_id_lookups.delete_all
		@venue.update_columns(instagram_id: nil)
		@venue.set_instagram_location_id(100)
	end

	def reset_foursquare_id 
		@venue.update_columns(foursquare_id: nil)
		@venue.add_foursquare_details
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

	def venue_primer
		render json: { success: true }
	end

	def cluster_primer
		venue_ids = params[:cluster_venue_ids].split(',').map(&:to_i)
		render json: { success: true }
	end

	def request_moment
		venue = Venue.find_by_id(params[:venue_id])
		mr = MomentRequest.where("venue_id = ? AND expiration >= ?", params[:venue_id], Time.now).first
		no_errors = false
		if mr
			mru = MomentRequestUser.create!(:user_id => params[:user_id], :moment_request_id => mr.id)
			mr.increment!(:num_requesters, 1)
			no_errors = true
		else
			mr = MomentRequest.create(:venue_id => params[:venue_id], :user_id => params[:user_id], :latitude => params[:latitude], :longitude => params[:longitude], :expiration => Time.now+30.minutes, :num_requesters => 1)				
			mru = MomentRequestUser.create!(:user_id => params[:user_id], :moment_request_id => mr.id)
			mr.increment!(:num_requesters, 1)
			venue.update_columns(moment_request_details: mr.to_json)
			no_errors = true
		end

		if no_errors
			render json: { success: true }
		else
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["Moment Request Failed"] } }, :status => :not_found
		end
	end

	def delete_moment_request
		mr = MomentRequest.find_by_id(params[:moment_request_id])
		if mr.delete
			render json: { success: true }
		else
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["Moment Request Deletion Failed"] } }, :status => :not_found
		end
	end

	def post_comment
		if params[:proposed_location] == true or params[:formatted_address] == nil
			is_proposed_location = true
		end

		if params[:venue_id] != nil
			venue = Venue.find_by_id(params[:venue_id])
		else
			venue = Venue.fetch_or_create(params[:name], params[:formatted_address], params[:city], params[:state], params[:country], params[:postal_code], params[:phone_number], params[:latitude], params[:longitude], is_proposed_location)
		end

		user = User.find_by_authentication_token(params[:auth_token])

		post = {:comment => params[:comment], :media_type => params[:media_type], :media_dimensions => params[:media_dimensions], :image_url_1 => params[:image_url_3], :image_url_2 => params[:image_url_3], :image_url_3 => params[:image_url_3], :video_url_1 => params[:video_url_1], :video_url_2 => params[:video_url_2], :video_url_3 => params[:video_url_3], :created_at => Time.now, :reaction => params[:reaction], :position_index => (Time.now+30.minutes).to_i}
		vc = venue.add_new_post(user, post)

		if vc
			render json: vc
		else
			render json: { error: { code: ERROR_UNPROCESSABLE, messages: vc.errors.full_messages } }, status: :unprocessable_entity
		end
	end

	def get_comments_feed
		page = params[:page].to_i
		venue_id = params[:venue_id].to_i

		@user = User.find_by_authentication_token(params[:auth_token])
		if venue_id != nil && venue_id != 0
			@venue = Venue.find_by_id(params[:venue_id])
		else
			@venue = Venue.fetch_or_create(params[:name], params[:address], params[:city], params[:state], params[:country], params[:postal_code], params[:phone_number], params[:latitude], params[:longitude])
		end

		if params[:from_search] == "1" && page == 1
			@user.delay.update_interests(@venue, "searched_venue")
		end

		if Time.now.min >= 10
			time_key = Time.now.min - Time.now.min%10
		else
			time_key = 0
		end		

		@view_cache_key = "venues/#{@venue.id}/#{@venue.latest_posted_comment_time.to_i}/comments/view/#{time_key}/page_#{page}"

		if Rails.cache.exist?(@view_cache_key) == true and (@venue.latest_posted_comment_time != nil and @venue.latest_posted_comment_time > Time.now - 5.hours)
			p "Rendering view from cache"
			render 'get_comments_feed.json.jbuilder'
		else
			p "Rebuilding views"
			Rails.cache.write(@view_cache_key, Time.now, :expires_in => 10.minutes)			
			@comments = @venue.content_feed_page(page)
			@view_cache_key = "venues/#{@venue.id}/#{@venue.latest_posted_comment_time.to_i}/comments/view/#{time_key}/page_#{page}"
			render 'get_comments_feed.json.jbuilder'
		end

		@venue.delay.account_page_view(@user.id, params[:is_favorite])
	end


	#for version 1.1.0
	def get_comments
		num_elements_per_page = 10
		page = params[:page].to_i
		venue_ids = params[:cluster_venue_ids].split(',').map(&:to_i)

		if venue_ids.count == 1
			@venue = Venue.find_by_id(venue_ids.first)
			@venue_id = @venue.id
			@venue.delay.account_page_view(@user.id)

			if params[:meta_query] != nil
				@comments = VenueComment.where("venue_id = ?", @venue.id).meta_search(params[:meta_query]).order("time_wrapper DESC").page(params[:page]).per(10)#VenueComment.meta_search_results(@venue.id, params[:meta_query]).page(params[:page]).per(10)
				render 'pure_comments.json.jbuilder'
			else						
				instagrams_cache_key = "venue/#{venue_ids.first}/latest_instagrams"
				latest_venue_instagrams = Rails.cache.fetch(instagrams_cache_key)
				if latest_venue_instagrams == nil
					latest_venue_instagrams = @venue.update_comments
					#in version 1.1.0 the next page is not pulled if there is less than 6 elements returned on the previous page.
					#To resolve this we introduce this hack to backfill the last element enough time so that the size of the array is
					#6. These dupes are then filtered out on the front.
					if (latest_venue_instagrams.length%num_elements_per_page) != 0 && latest_venue_instagrams.last != nil
						if latest_venue_instagrams.length < num_elements_per_page
							(num_elements_per_page - latest_venue_instagrams.length).times{latest_venue_instagrams <<  latest_venue_instagrams.last}
						else
							(num_elements_per_page - (latest_venue_instagrams.length%num_elements_per_page)).times{latest_venue_instagrams <<  latest_venue_instagrams.last}						
						end
						Rails.cache.write(instagrams_cache_key, latest_venue_instagrams, :expires_in => 10.minutes)
					else						
						Rails.cache.write(instagrams_cache_key, latest_venue_instagrams, :expires_in => 10.minutes)
					end
				end

				latest_instagrams_count = latest_venue_instagrams.length

				@view_cache_key = "venue/#{venue_ids.first}/comments/page#{params[:page]}/view"
				if (latest_instagrams_count > 0) && (num_elements_per_page*(page-1) < latest_instagrams_count)
					start_index = (page-1)*(num_elements_per_page)
					end_index = start_index+(num_elements_per_page-1)
					@comments = latest_venue_instagrams[start_index..end_index]
					render 'dirty_comments.json.jbuilder'
				else
					offset_page = page - (latest_instagrams_count.to_f/num_elements_per_page.to_f).ceil
					vc_cache_key = "venue/#{venue_ids.first}/comments/page#{params[:page]}"
					@comments = Rails.cache.fetch(vc_cache_key, :expires_in => 10.minutes) do
						VenueComment.where("venue_id = ? AND created_at <= ?", @venue_id, Time.now-10.minutes).order("time_wrapper DESC").limit(10).offset((offset_page-1)*10)
					end
					if params[:version] == "1.1.0"
						render 'pure_comments_1.1.0_patch.json.jbuilder'
					else
						render 'pure_comments.json.jbuilder'
					end
				end
			end
		else
			cache_key = "cluster/cluster_#{venue_ids.length}_#{params[:cluster_latitude]},#{params[:cluster_longitude]}/comments/page#{params[:page]}"
			#@comments = VenueComment.joins(:venue).where("venues.id in (#{params[:cluster_venue_ids]})").order("time_wrapper DESC").page(page).per(10)
			@comments = VenueComment.where("venue_id IN (?)", venue_ids).order("time_wrapper desc").page(page).per(10)
			@venue = nil
			if params[:version] == "1.1.0"
				render 'pure_comments_1.1.0_patch.json.jbuilder'
			else
				render 'pure_comments.json.jbuilder'
			end
		end	
	end

#depricated
	def get_comments_implicitly
		num_elements_per_page = 10
		page = params[:page].to_i

		if params[:country] != nil
			@venue = Venue.fetch_or_create(params[:name], params[:formatted_address], params[:city], params[:state], params[:country], params[:postal_code], params[:phone_number], params[:latitude], params[:longitude])
			#Venue.fetch(params["name"], params["formatted_address"], params["city"], params["state"], params["country"], params["postal_code"], params["phone_number"], params["latitude"], params["longitude"])
		else
			@venue = Venue.fetch_venues_for_instagram_pull(params[:name], params[:latitude].to_f, params[:longitude].to_f, params[:instagram_location_id], nil)
		end
		#@venue.delay.account_page_view(@user.id)		

		instagrams_cache_key = "venue/#{@venue.id}/latest_instagrams"

		latest_venue_instagrams = Rails.cache.fetch(instagrams_cache_key)
		if latest_venue_instagrams == nil
			latest_venue_instagrams = @venue.update_comments
			#in version 1.1.0 the next page is not pulled if there is less than 6 elements returned on the previous page.
			#To resolve this we introduce this hack to backfill the last element enough time so that the size of the array is
			#6. These dupes are then filtered out on the front.
			if (latest_venue_instagrams.length%num_elements_per_page) != 0 && latest_venue_instagrams.last != nil
				if latest_venue_instagrams.length < num_elements_per_page
					(num_elements_per_page - latest_venue_instagrams.length).times{latest_venue_instagrams <<  latest_venue_instagrams.last}
				else
					(num_elements_per_page - (latest_venue_instagrams.length%num_elements_per_page)).times{latest_venue_instagrams <<  latest_venue_instagrams.last}						
				end
				Rails.cache.write(instagrams_cache_key, latest_venue_instagrams, :expires_in => 10.minutes)
			else						
				Rails.cache.write(instagrams_cache_key, latest_venue_instagrams, :expires_in => 10.minutes)
			end
		end
		latest_instagrams_count = latest_venue_instagrams.length

		@view_cache_key = "venue/#{@venue.id}/comments/page#{params[:page]}/view"
		if (latest_instagrams_count > 0) && (num_elements_per_page*(page-1) < latest_instagrams_count)
			start_index = (page-1)*(num_elements_per_page)
			end_index = start_index+(num_elements_per_page-1)
			@comments = latest_venue_instagrams[start_index..end_index]
			@venue_id = @venue.id
			render 'dirty_comments.json.jbuilder'
		else
			offset_page = page - (latest_instagrams_count.to_f/num_elements_per_page.to_f).ceil
			vc_cache_key = "venue/#{@venue.id}/comments/page#{params[:page]}"
			@comments = Rails.cache.fetch(vc_cache_key, :expires_in => 10.minutes) do
				VenueComment.where("venue_id = ? AND created_at <= ?", @venue.id, Time.now-10.minutes).order("time_wrapper DESC").limit(10).offset((offset_page-1)*10)
			end
			@venue_id = @venue.id
			if params[:version] == "1.1.0"
				render 'pure_comments_1.1.0_patch.json.jbuilder'
			else
				render 'pure_comments.json.jbuilder'
			end
		end

	end	

	def get_venue_feeds
		@user = User.find_by_authentication_token(params[:auth_token])
		@feeds = Feed.feeds_in_venue(params[:venue_id]).page(params[:page]).per(10)
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

	def refresh_map_view
		Venue.delay(:priority => -2).surrounding_area_instagram_pull(params[:latitude], params[:longitude]) #this is to handle places not near a vortex
		cache_key = "lyt_map"
		@view_cache_key = cache_key+"/view"
		@venues = Rails.cache.fetch(cache_key, :expires_in => 5.minutes) do
			Venue.where("color_rating > -1.0").to_a
		end
		render 'display.json.jbuilder'
	end

	def refresh_map_view_by_parts
		page = params[:page].to_i
		lat = params[:latitude]
		long = params[:longitude]

		if page == 1
			@user.update_location(lat, long)
		end

		if params[:user_city] != nil
			city = params[:user_city]
		else
			search_box = Geokit::Bounds.from_point_and_radius([lat,long], 20, :units => :kms)
			city = InstagramVortex.in_bounds(search_box).order("id ASC").first.city rescue "New York"
			#city = InstagramVortex.within(20, :units => :kms, :origin => [lat, long]).order("id ASC").first.city rescue "New York"
		end

		if Time.now.min >= 10
			time_key = Time.now.min - Time.now.min%10
			previous_time_key = time_key - 10
		else
			time_key = 0
			previous_time_key = 50
		end

		@view_cache_key = "#{city}/lyt_map/view/#{Time.now.to_date}/#{Time.now.hour}/#{time_key}/page_#{page}"

		if Rails.cache.exist?(@view_cache_key) == true
			p "#{page} ------- DIRECT VIEW RENDER"
			if params[:version] == "1.1.0"
				render "refresh_map_view_by_parts_old.json.jbuilder"
			else
				render "refresh_map_view_by_parts_with_time.json.jbuilder"
			end
		elsif page > 1 && Rails.cache.exist?("#{city}/lyt_map/view/#{previous_time_key}/page_#{page}") == true
			p "#{page} ^^^^^^^ RENDERING PREVIOUS SEGMENT VIEW"
			@view_cache_key = "#{city}/lyt_map/view/#{Time.now.to_date}/#{Time.now.hour}/#{previous_time_key}/page_#{page}"
			if params[:version] == "1.1.0"
				render "refresh_map_view_by_parts_old.json.jbuilder"
			else
				render "refresh_map_view_by_parts_with_time.json.jbuilder"
			end
		else
			p "#{page} $$$$$$$ RECACHING"
			city_cache_key = "#{city}/lyt_map/page_#{page}"

			#if page == 1
			#	num_page_entries = 300
			#else
			#	num_page_entries = 500
			#end

			num_page_entries = 300

			@venues = Rails.cache.fetch(city_cache_key, :expires_in => 10.minutes) do
				#this could go wrong if more than 300 active venues in 3km radius
				if page == 1
					venues = Venue.close_to(lat, long, 5000).select("id, name, address, city, country, latitude, longitude, color_rating, popularity_rank, instagram_location_id, latest_posted_comment_time, venue_comment_details, event_details, trending_tags, categories").where("color_rating > -1.0").order("color_rating DESC").limit(num_page_entries).offset((page-1)*num_page_entries).to_a rescue "error"
				end

				if page > 1 or venues.length == 0					
					if page == 1
					end
					venues = Venue.far_from(lat, long, 5000).select("id, name, address, city, country, latitude, longitude, color_rating, popularity_rank, instagram_location_id, latest_posted_comment_time, venue_comment_details, event_details, trending_tags, categories").where("color_rating > -1.0").order("color_rating DESC").limit(num_page_entries).offset((page-2)*num_page_entries).to_a rescue "error"
				else
					nil
				end

				if venues != "error"
					Rails.cache.write(@view_cache_key, time_key, :expires_in => 10.minutes)
				end

				venues		
			end

			if params[:version] == "1.1.0"
				render "refresh_map_view_by_parts_old.json.jbuilder"
			else
				render "refresh_map_view_by_parts_with_time.json.jbuilder"
			end

		end
	end

	def direct_fetch
		position_lat = params[:latitude]
		position_long = params[:longitude]

		ne_lat = params[:ne_latitude].to_f
		ne_long = params[:ne_longitude].to_f
		sw_lat = params[:sw_latitude].to_f
		sw_long = params[:sw_longitude].to_f

		view_box = {:ne_lat => ne_lat, :ne_long => ne_long, :sw_lat => sw_lat, :sw_long => sw_long}

		query = params[:q]

		if Venue.query_is_meta?(query) == true
			@venues = Venue.fetch(query, position_lat, position_long, view_box, true)
			@is_meta = true
		else
			@venues = Venue.fetch(query, position_lat, position_long, view_box, false)
			@is_meta = false
		end

		render 'search.json.jbuilder'
	end

	def meta_fetch
		position_lat = params[:latitude]
		position_long = params[:longitude]

		ne_lat = params[:ne_latitude]
		ne_long = params[:ne_longitude]
		sw_lat = params[:sw_latitude]
		sw_long = params[:sw_longitude]

		query = params[:q]
		@venues = Venue.where("latitude > ? AND latitude < ? AND longitude > ? AND longitude < ?", sw_lat, ne_lat, sw_long, ne_long).meta_search(query).limit(20)
		render 'search.json.jbuilder'
	end

	def get_venue_contexts
		@venue = Venue.find_by_id(params[:venue_id])			
	end

	def get_cluster_contexts
		@contexts = MetaData.cluster_top_meta_tags(params[:cluster_venue_ids])
		@key = "contexts/cluster/#{params[:cluster_venue_ids].first(10)}_#{params[:cluster_venue_ids].length}"
		render 'get_cluster_contexts.json.jbuilder'
	end

	def explore_venues
		previous_venue_ids = params[:previous_venue_ids]
		if previous_venue_ids == nil
			previous_venue_ids = []
		else
			previous_venue_ids = previous_venue_ids.split(',').map(&:to_i)
		end
		@venue = Venue.discover(params[:proximity], params[:previous_venue_ids], params[:latitude], params[:longitude])
	end

	def get_trending_venues_for_user_list_feed
		@venues = Venue.trending_venues_for_user(params[:latitude], params[:longitude])
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


	def check_vortex_proximity
		@user = User.find_by_authentication_token(params[:auth_token])
		@user.delay(:priority => -1).update_feeds_and_favorites
		lat = params[:latitude]
		long = params[:longitude]
		InstagramVortex.check_nearby_vortex_existence(lat, long)
		render json: { success: true }
	end

	def add_to_favorites
		@user = User.find_by_authentication_token(params[:auth_token])
		venue = Venue.find_by_id(params[:venue_id])
		fv = FavoriteVenue.create!(:venue_id => venue.id, :venue_name => venue.name, :user_id => params[:user_id], :venue_details => venue.partial)

		if fv
			@user.delay.update_interests(venue, "favorited_venue")
			render json: fv
		else
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["Venue Not Favorited"] } }, :status => :not_found
		end
	end

	def remove_from_favorites
		if params[:favorite_venue_id]
			fv = FavoriteVenue.find_by_id(params[:favorite_venue_id])
		else
			fv = FavoriteVenue.where("venue_id = ? AND user_id = ?", params[:venue_id], params[:user_id]).first
		end

		if fv.delete
			render json: { success: true }
		else
			render json: { error: { code: ERROR_NOT_FOUND, messages: ["Failed to Remove From Favorites"] } }, :status => :not_found
		end
	end

	def get_events
		@events = Event.where("venue_id = ?", params[:venue_id])
	end

	def get_lytit_featured_venue
		featured_venue_id = 0
		@venue = Venue.find_by_id(featured_venue_id)
	end

	def get_surrounding_venues
		lat = params[:latitude]
		long = params[:longitude]
		@venues = Venue.nearest_neighbors(lat, long, 0.45, 5)
		render 'search.json.jbuilder'
	end


	private

	def venue
		@venue ||= Venue.find(params[:venue_id])
	end

	def venue_comment_params
		params.permit(:comment, :media_type, :media_url, :session)
	end
end
